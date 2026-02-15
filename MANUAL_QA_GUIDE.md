# Manual QA Guide - Phase 1

## Prerequisites

1. **Grant Permissions** (one-time setup):
   - Run the app: `swift run`
   - When prompted, grant **Input Monitoring** permission
   - Grant **Accessibility** permission
   - Restart the app after granting permissions

2. **Create Test Snippets**:
   - Open Snippet Manager from menu bar
   - Create 5-10 test snippets with various content
   - Include multiline text, code snippets, special characters

## QA Test Cases

### 1. Menu Bar Presence
- [ ] App icon appears in menu bar (no dock icon)
- [ ] Clicking icon shows dropdown menu
- [ ] Menu contains: Search Snippets, Manage Snippets, Settings, Quit
- [ ] "Manage Snippets" opens management window
- [ ] "Settings" opens settings window
- [ ] "Quit" terminates the app

### 2. Global Hotkey Trigger
- [ ] Open TextEdit (or any text editor)
- [ ] Press **Cmd+Shift+Space**
- [ ] Floating panel appears near cursor
- [ ] Panel has search field + snippet results
- [ ] Search field is auto-focused (can type immediately)

### 3. Panel Positioning
- [ ] Panel appears near mouse cursor
- [ ] Panel doesn't go off-screen at bottom edge
- [ ] Panel doesn't go off-screen at right edge
- [ ] Panel doesn't go off-screen at left edge
- [ ] If using multiple monitors, test on secondary monitor
- [ ] Panel appears above fullscreen apps (test in fullscreen mode)

### 4. Search Functionality
- [ ] Type "mfa" → filters to matching snippets
- [ ] Clear search → shows all snippets
- [ ] Search matches title
- [ ] Search matches content
- [ ] Search is case-insensitive ("MFA" matches "mfa")
- [ ] Shows max 20 results
- [ ] Empty state message when no snippets match

### 5. Keyboard Navigation
- [ ] Press **↓** → selection moves down
- [ ] Press **↑** → selection moves up
- [ ] Selection wraps at top/bottom
- [ ] Selected snippet highlighted (accent color background)
- [ ] Press **Enter** → inserts selected snippet
- [ ] Press **Escape** → closes panel

### 6. Text Insertion
Open each app below, trigger panel, select snippet, verify insertion:
- [ ] **TextEdit**: Text appears at cursor position
- [ ] **VS Code**: Text appears at cursor position
- [ ] **Terminal**: Text appears at prompt
- [ ] **Slack** (browser): Text appears in message box
- [ ] **Notes app**: Text appears at cursor

### 7. Clipboard Preservation
- [ ] Copy "CLIPBOARD TEST" to clipboard
- [ ] Open panel, insert a snippet
- [ ] Paste (Cmd+V) → should paste "CLIPBOARD TEST" (original clipboard restored)
- [ ] Try with image in clipboard (copy screenshot, insert snippet, verify image still in clipboard)

### 8. Usage Count Tracking
- [ ] Note current usage count of a snippet (in Snippet Manager)
- [ ] Insert that snippet 3 times
- [ ] Check Snippet Manager → usage count increased by 3

### 9. Panel Dismissal
- [ ] Open panel, click outside panel → panel closes
- [ ] Open panel, press Escape → panel closes
- [ ] Open panel, switch to another app → panel stays visible (non-activating)
- [ ] Open panel, press Cmd+Shift+Space again → panel closes (toggle)

### 10. Permissions Flow
- [ ] Open Settings → Permissions tab
- [ ] If granted: green checkmark shows for both permissions
- [ ] Revoke Input Monitoring in System Settings
- [ ] Restart app, try hotkey → doesn't work
- [ ] Settings shows red X for Input Monitoring
- [ ] Click "Grant" → opens System Settings to correct pane
- [ ] Re-grant permission, restart app
- [ ] Hotkey works again

### 11. Edge Cases
- [ ] Create snippet with emoji: 🚀🎉 → inserts correctly
- [ ] Create snippet with newlines → preserves formatting
- [ ] Create snippet with special chars: `!@#$%^&*()` → inserts correctly
- [ ] Empty snippet library → panel shows "No snippets yet" message
- [ ] Very long snippet (>1000 chars) → preview truncates, full text inserts
- [ ] Search with no matches → shows "No matches for 'xyz'" message

## Success Criteria

All checkboxes above must pass. If any fail, document the issue and fix before proceeding to Phase 2.

## Common Issues & Fixes

**Hotkey doesn't work:**
- Check Settings → Permissions → Input Monitoring is granted
- Restart app after granting permission
- Check Console.app for error messages

**Snippet doesn't insert:**
- Check Settings → Permissions → Accessibility is granted
- Verify target app supports paste (Cmd+V)
- Check if snippet was copied to clipboard (Cmd+V manually)

**Panel appears off-screen:**
- Test on different monitor configurations
- Report cursor position + screen bounds in issue

**Clipboard not restored:**
- Verify 100ms delay is sufficient for slow apps
- Test with different content types (text, images, files)

## Reporting Issues

For each failed test:
1. Document exact steps to reproduce
2. Include macOS version, app versions
3. Check Console.app for error logs
4. Screenshot if visual issue

---

**QA Tester**: _____________
**Date**: _____________
**Result**: [ ] PASS  [ ] FAIL
**Notes**: _____________
