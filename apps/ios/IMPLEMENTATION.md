# Implementation evidence

Implemented locally on 2026-09-28/29 from the approved iOS plan. Verified steps are
committed separately. No pushes, remote CI dispatches, real-provider requests, VPN
changes or store uploads.

## Delivered

- iPhone app and widget extension, iOS 26+, shared Swift models and existing host client.
- HTTPS/read-token pairing, QR scan, Keychain storage, bounded foreground polling,
  last-good cache, host/account identity isolation and explicit revoked/offline states.
- Usage, Widgets and Settings; quota detail, provider analytics, privacy mode,
  four-language String Catalog, native navigation and reduced-motion handling.
- Six configurable widget families with per-instance host/account/metric selection,
  deep links and opportunistic read-only updates.
- macOS Settings sharing controls, QR/manual credential details and device revocation.
- CLI `devices add/list/revoke`; local-only sharing API with a second read-only
  listener sharing one scheduler/vault. Disable also blocks old keep-alive requests.
- Windows DPAPI storage, OS file locking and replacement are included with
  platform-specific tests. Native Windows runtime verification remains pending.
- iOS CI for model and simulator tests; checked-in Xcode project and generator spec.

## Checks

- HostClient: 4 tests passed, including status compatibility and empty revocation responses.
- Mobile models: 6 tests passed.
- Unsigned iOS Release archive succeeded at `/private/tmp/QuotioIOS.xcarchive`; signing/export are unverified.
- iOS Simulator: app + widget build; 2 UI tests and 1 app integration test passed.
  The integration test uses synthetic HTTP responses but real isolated Keychain and
  filesystem storage; verifies pairing, persistence, revocation and deletion.
- Rust full suite: 554 passed, 1 ignored. Later companion shutdown regression passed.
- QuotioCore: 503 executed, 1 skipped, 0 failures. macOS Debug app build passed.
- macOS architecture check, Rust Clippy with warnings denied, actionlint and diff
  whitespace checks passed.
- Windows GNU cross-check of all targets/features passed. Existing Windows-specific
  unused/dead-code warnings remain. This is compilation, not Windows runtime proof.
- Light/Dark Simulator screens inspected. Provider logos use template rendering;
  copied SVG dimensions were normalized for the iOS asset compiler.

## Pending external acceptance

- Run the storage and host tests on Windows CI. The user has no Windows host
  available. Cross-compilation alone does not establish native-Windows support
  or release readiness.
- Physical iPhone LAN/VPN/TLS and camera, widget scheduling while locked, sleep/wake,
  actual accessibility inspection and native-provider acceptance on each host OS.
- Final opaque iOS App Store icon, distribution export, TestFlight processing and
  store metadata/privacy review. Local development signing is verified below.
- No progress-events contract exists; task progress and Live Activities remain deferred
  as approved. No public cloud relay or APNs infrastructure was introduced.

## Known boundaries

Sharing readiness means the local companion listener is listening. It does not test
an external HTTPS reverse proxy. Configure that proxy separately and retain the
original local owner endpoint for OS approval. Device codes are credentials valid
until expiry/revocation, not one-use pairing sessions.

The widget gallery describes the supported families and previews current quota;
full pixel previews for every family and device still need device-level visual QA.

CI runner labels were checked against [GitHub runner images](https://github.com/actions/runner-images) on 2026-09-28. The workflows have not run remotely.

## Local signing follow-up, 2026-09-29

Debug now reads ignored `Config/Local.xcconfig`, matching the macOS convention.
Release keeps machine-specific values out of its base configuration; the local
signed archive uses an explicit `-xcconfig` override. The example and generated
project contain no team ID. No team ID was added to Git-visible content.

The app and widget both built with Apple Development signing. Strict/deep signature
verification, the requested team, App Group and shared Keychain entitlements passed
for both bundles and the Release archive. The signed development archive is at
`/private/tmp/QuotioIOS-signed-20260929.xcarchive`. This is not an App Store distribution
export and was not uploaded. Real-device acceptance remains pending.

## Windows commit verification, 2026-09-29

Windows GNU cross-check passed for all targets/features. The affected cache,
contract, device-command, server-management, vault and settings checks passed on
macOS: 57 passed and 1 ignored. Formatting and diff checks passed.

The full concurrent Rust suite had one Cursor WAL snapshot-cleanup failure in
unchanged provider code. That test passed in isolation. This is recorded separately
from the passing affected checks; the full-suite run was not green. Native Windows
execution remains pending CI.

## Sharing UX and menu-bar pairing, 2026-09-29

The active iPhone sharing page now separates host state, authorized devices and
connection settings. Pairing is available directly from the menu bar in an AppKit
popover using the same SwiftUI flow and model as Settings. Opening it does not open
the main window or issue a token. First-time HTTPS setup is available in the popover;
the upstream port is under Advanced. Device grants remain read-only with their actual
expiry; this does not introduce one-use pairing links or online-device tracking.

The old unused SettingsScreen and ten orphaned components were removed. Still-used
settings sections and the proxy version manager were moved into dedicated files
without changing their view bodies. Tests passed before and after cleanup.

New tests cover retained in-flight issuance, no duplicate grant on reopen, expiry,
revocation, endpoint changes, persisted configuration, specific service errors,
menu command routing without opening the app, and native popover dismissal when
Settings takes over. Synthetic QR layouts were rendered in Light/Dark appearances.
Physical iPhone QR scanning and LAN/VPN reachability still need device acceptance.
