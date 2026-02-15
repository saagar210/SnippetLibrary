#!/usr/bin/env swift

import Foundation

// This script creates test snippets for manual QA

let testSnippets = [
    ("MFA Reset Instructions", """
To reset your MFA device:
1. Log into the IT portal
2. Navigate to Security → Multi-Factor Auth
3. Click "Reset MFA Device"
4. Follow the QR code scanning instructions
5. Verify with a test login

If you encounter issues, contact IT support.
""", "plaintext"),

    ("Password Policy", """
Corporate password requirements:
- Minimum 12 characters
- At least 1 uppercase letter
- At least 1 number
- At least 1 special character (!@#$%^&*)
- Cannot reuse last 5 passwords
- Expires every 90 days
""", "plaintext"),

    ("VPN Setup macOS", """
# VPN Configuration for macOS

1. Open System Settings → Network
2. Click + button, select VPN
3. VPN Type: IKEv2
4. Server Address: vpn.company.com
5. Remote ID: vpn.company.com
6. Local ID: your.email@company.com
7. Authentication: Username
8. Enter your AD credentials
9. Click Connect

Test with: ping internal.company.com
""", "markdown"),

    ("SQL User Query", """
SELECT
    u.id,
    u.username,
    u.email,
    u.created_at,
    COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.status = 'active'
GROUP BY u.id
ORDER BY u.created_at DESC
LIMIT 100;
""", "sql"),

    ("Swift Error Handling", """
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingFailed
}

func fetchData<T: Codable>(from url: URL) async throws -> T {
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw NetworkError.noData
    }

    return try JSONDecoder().decode(T.self, from: data)
}
""", "swift")
]

print("Test snippets to create:")
for (i, (title, content, language)) in testSnippets.enumerated() {
    print("\(i+1). \(title) (\(language))")
}
