# Quotio for iPhone

Quotio displays host-owned quota and analytics over HTTPS on a LAN or private VPN.
It includes native Usage, Widgets and Settings tabs and six WidgetKit families.
Provider credentials stay on the computer. The phone receives a revocable read-only
credential, stored in Keychain. No Quotio cloud service is required.

## Build and test

Open `Quotio.xcodeproj`, select `QuotioIOS` and an iOS 26+ iPhone Simulator.
The checked-in project builds without XcodeGen. To regenerate after adding files:

```sh
xcodegen generate --spec apps/ios/project.yml
swift test --package-path apps/ios
swift test --package-path Packages/QuotioHostClient
xcodebuild -project apps/ios/Quotio.xcodeproj -scheme QuotioIOS -showdestinations
```

Run `xcodebuild test` with a destination listed by the last command. The scheme
includes the widget extension and UI tests. Explore Demo works offline with clearly
labelled synthetic data; it does not persist demo accounts or credentials.

For physical devices, copy `Config/Local.xcconfig.example` to
`Config/Local.xcconfig` and set your signing team there. The local file is ignored
by Git; never put the team ID in `project.yml` or the generated project. Debug
includes it automatically, matching the macOS setup. Release intentionally does
not include it; explicitly pass it when creating a local signed archive:

```sh
xcodebuild -project apps/ios/Quotio.xcodeproj -scheme QuotioIOS \
  -configuration Release -destination 'generic/platform=iOS' \
  -xcconfig apps/ios/Config/Local.xcconfig -allowProvisioningUpdates \
  -archivePath /tmp/QuotioIOS-signed.xcarchive archive
```

Use the same team for app and widget, with App Group
`group.app.bytrong.quotio.ios` and Keychain group
`$(AppIdentifierPrefix)app.bytrong.quotio.ios.hosts`. Automatic signing needs access
to that team's certificates and profiles. Simulator builds retain ad-hoc signing.
Do not commit certificates, provisioning profiles, archives or signing secrets.

## Connect a CLI host

Start a current host with saved-account storage, management enabled, an owner token
in `QUOTIO_SERVER_TOKEN`, and an external HTTPS origin. The Rust listener stays on
loopback. macOS uses Keychain; Linux also needs its documented vault master key.

```sh
quotio serve --manage --public-url https://computer.example --listen 127.0.0.1:6767
quotio devices add --label iPhone --public-url https://computer.example
quotio devices list
quotio devices revoke CLIENT_ID
```

The `devices` commands read the same owner token from the environment and call the
local owner API. The `add` output is sensitive JSON returned once. Enter its origin
and device token in iPhone, or encode the JSON as a QR locally and scan in Quotio.
Never share the owner token with the phone. Lost issuance output: list/revoke that
device and issue again, rather than retrying blindly.

Configure an HTTPS reverse proxy on the host forwarding to loopback and preserving
Host and Authorization. Its Host must match `--public-url`. Restrict exposure to LAN
or private VPN. Tailscale Serve is one supported deployment approach, not an app
dependency. Plain LAN also needs a trusted certificate and matching hostname. There
is no insecure TLS switch, automatic VPN installation or public tunnel.

## Connect the macOS app

Choose Pair iPhone… directly in the Quotio menu. A compact pairing view opens
without opening the main window, including first-time address setup. Enter your
HTTPS address, enable sharing, name the device and create its code. The local
upstream port is under Advanced. Use Settings… → iPhone sharing to review and
revoke authorized devices.
Point your HTTPS proxy at that local port. Scan the code inside Quotio iPhone and
confirm the address before connecting. Manual details let you copy the device token.
Closing the pairing view preserves the current code in memory; reopening it does
not issue another credential. Done clears the displayed code without revoking the
device. Codes also disappear on expiry, revocation or an endpoint change. Existing
grants cannot be displayed again after their in-memory code has been cleared.

The companion listener shares the existing Rust process, vault and scheduler. It
accepts delegated reads only; the original local owner listener retains native
permission/OAuth authority. Disabling sharing stops new companion requests, including
requests on old keep-alive connections. Already-started reads may finish.

This Mac must be awake and Quotio must remain running. “Local listener ready” does
not certify the external proxy, certificate, VPN or iPhone reachability.

## Widgets, privacy and data

Add Quotio using the system Home Screen or Lock Screen editor. Configure each
instance with a host/account/window and used/remaining preference. Tapping opens the
same account. Widgets never merge identities between computers.

WidgetKit chooses update times. Cached data, host sleep, unavailable VPN and expired
credentials are visible states. Pull-to-refresh in the app reads a snapshot; it does
not trigger a provider refresh with a read-only token. Missing quota is not zero;
reset deadlines do not imply quota has returned to 100%.

Charts use provider-reported dates and the 30 most recent reported buckets, not an
invented continuous 30-day history. Privacy mode hides values and chart shapes,
including VoiceOver and widgets. Lock Screen widgets do not display account names.
Already-rendered system widget content may persist until iOS processes a reload.

Removing a host deletes its local token/cache; revoke on the computer to invalidate
access. Device grants expire after 30 days by default. Keychain credentials are
ThisDeviceOnly, available after first unlock, and do not sync through iCloud.

## Windows and release status

The native Windows backend includes per-user DPAPI storage, file locking and
atomic replacement. Runtime verification remains pending on Windows. Cross-compilation
on macOS is not a DPAPI or Windows-device test; do not advertise Windows support
before those checks pass.

Before TestFlight: supply the signing team and group provisioning, validate on a
physical iPhone over LAN and VPN, exercise widget timing outside developer mode,
verify fresh/revoked credentials on each host OS, archive and inspect entitlements.
No APNs, Live Activities or task-progress source is included in this release.

The inherited macOS app-icon PNG currently retains an alpha channel. Replace it
with the final opaque iOS icon before App Store validation. The source is retained
unchanged until that distribution asset is prepared.
