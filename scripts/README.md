# Scripts

Small entrypoints only. Keep shared constants and output helpers in `config.sh`.

## Debug

- `debug.sh`: build Debug, stop any running Quotio process, and launch the fresh app. Optional flags: `--verify`, `--logs`.

## Build And Package

- `build.sh`: create a Release archive, extract `Quotio.app`, verify the bundled proxy, and ad-hoc sign the app.
- `package.sh`: create release ZIP and DMG artifacts from `build/Quotio.app`.
- `notarize.sh`: optionally notarize and staple the built app when the configured notarytool keychain profile exists.
- `verify-bundled-proxy.sh`: verify the bundled `cli-proxy-api-plus` checksum against the app model source.

## Release

- `bump-version.sh`: update Xcode marketing/build versions.
- `update-changelog.sh`: move unreleased changelog content into a version section.
- `generate-appcast.sh`: generate a local Sparkle appcast using local Sparkle tools.
- `generate-appcast-ci.sh`: generate a CI appcast using `SPARKLE_PRIVATE_KEY`.
- `release.sh`: full local release workflow for build, optional notarization, packaging, local appcast, tag, and GitHub release.
