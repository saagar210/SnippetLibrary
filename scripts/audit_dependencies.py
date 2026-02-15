#!/usr/bin/env python3
"""Audit Swift package dependencies against OSV by repository+revision."""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path

OSV_QUERY_URL = "https://api.osv.dev/v1/query"


@dataclass
class Pin:
    identity: str
    location: str
    revision: str
    version: str | None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check Package.resolved pins for known OSV vulnerabilities."
    )
    parser.add_argument(
        "--resolved",
        default="Package.resolved",
        help="Path to Package.resolved (default: Package.resolved)",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=10.0,
        help="HTTP timeout in seconds (default: 10)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON output in addition to human-readable summary.",
    )
    return parser.parse_args()


def load_pins(path: Path) -> list[Pin]:
    with path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)

    pins: list[Pin] = []
    for raw_pin in data.get("pins", []):
        identity = raw_pin.get("identity")
        location = raw_pin.get("location")
        state = raw_pin.get("state", {})
        revision = state.get("revision")
        version = state.get("version")

        if not identity or not location or not revision:
            continue

        pins.append(Pin(identity=identity, location=location, revision=revision, version=version))
    return pins


def query_osv(pin: Pin, timeout: float) -> tuple[list[dict], str | None]:
    payload = {
        "commit": pin.revision,
        "repo": pin.location,
    }
    body = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        OSV_QUERY_URL,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read().decode("utf-8")
            data = json.loads(raw)
    except urllib.error.HTTPError as error:
        return [], f"HTTP {error.code}"
    except urllib.error.URLError as error:
        return [], f"network error: {error.reason}"
    except TimeoutError:
        return [], "timeout"
    except json.JSONDecodeError:
        return [], "invalid JSON response"

    vulns = data.get("vulns", []) or []
    if not isinstance(vulns, list):
        return [], "invalid schema"
    return vulns, None


def main() -> int:
    args = parse_args()
    resolved_path = Path(args.resolved)

    if not resolved_path.exists():
        print(f"error: file not found: {resolved_path}", file=sys.stderr)
        return 2

    pins = load_pins(resolved_path)
    if not pins:
        print(f"no pins found in {resolved_path}")
        return 0

    findings: list[dict] = []
    errors: list[dict] = []

    for pin in pins:
        vulns, error = query_osv(pin, args.timeout)
        if error:
            errors.append({"package": pin.identity, "error": error})
            continue

        if vulns:
            findings.append(
                {
                    "package": pin.identity,
                    "location": pin.location,
                    "revision": pin.revision,
                    "version": pin.version,
                    "vulns": vulns,
                }
            )

    print(f"audited {len(pins)} pinned dependencies from {resolved_path}")

    if findings:
        print("")
        print("vulnerabilities found:")
        for finding in findings:
            print(f"- {finding['package']} ({finding.get('version') or finding['revision']})")
            for vuln in finding["vulns"]:
                vuln_id = vuln.get("id", "UNKNOWN")
                summary = vuln.get("summary", "").strip()
                if summary:
                    print(f"  - {vuln_id}: {summary}")
                else:
                    print(f"  - {vuln_id}")
    else:
        print("no known vulnerabilities reported by OSV for pinned revisions")

    if errors:
        print("")
        print("scan errors:")
        for error in errors:
            print(f"- {error['package']}: {error['error']}")

    if args.json:
        print("")
        print(
            json.dumps(
                {
                    "scanned_count": len(pins),
                    "findings": findings,
                    "errors": errors,
                },
                indent=2,
                sort_keys=True,
            )
        )

    if findings:
        return 1
    if errors:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
