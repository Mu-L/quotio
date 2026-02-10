# Quotio/Services/Proxy/CLIProxyManager.swift

[← Back to Module](../modules/root/MODULE.md) | [← Back to INDEX](../INDEX.md)

## Overview

- **Lines:** 1970
- **Language:** Swift
- **Symbols:** 64
- **Public symbols:** 0

## Symbol Table

| Line | Kind | Name | Visibility | Signature |
| ---- | ---- | ---- | ---------- | --------- |
| 9 | class | CLIProxyManager | (internal) | `class CLIProxyManager` |
| 191 | method | init | (internal) | `init()` |
| 232 | fn | restartProxyIfRunning | (private) | `private func restartProxyIfRunning()` |
| 250 | fn | updateConfigValue | (private) | `private func updateConfigValue(pattern: String,...` |
| 270 | fn | updateConfigPort | (private) | `private func updateConfigPort(_ newPort: UInt16)` |
| 274 | fn | updateConfigHost | (private) | `private func updateConfigHost(_ host: String)` |
| 278 | fn | ensureApiKeyExistsInConfig | (private) | `private func ensureApiKeyExistsInConfig()` |
| 327 | fn | updateConfigAllowRemote | (internal) | `func updateConfigAllowRemote(_ enabled: Bool)` |
| 331 | fn | updateConfigLogging | (internal) | `func updateConfigLogging(enabled: Bool)` |
| 339 | fn | updateConfigRoutingStrategy | (internal) | `func updateConfigRoutingStrategy(_ strategy: St...` |
| 344 | fn | updateConfigProxyURL | (internal) | `func updateConfigProxyURL(_ url: String?)` |
| 372 | fn | applyBaseURLWorkaround | (internal) | `func applyBaseURLWorkaround()` |
| 401 | fn | removeBaseURLWorkaround | (internal) | `func removeBaseURLWorkaround()` |
| 443 | fn | ensureConfigExists | (private) | `private func ensureConfigExists()` |
| 477 | fn | syncSecretKeyInConfig | (private) | `private func syncSecretKeyInConfig()` |
| 493 | fn | regenerateManagementKey | (internal) | `func regenerateManagementKey() async throws` |
| 528 | fn | syncProxyURLInConfig | (private) | `private func syncProxyURLInConfig()` |
| 541 | fn | syncCustomProvidersToConfig | (private) | `private func syncCustomProvidersToConfig()` |
| 558 | fn | downloadAndInstallBinary | (internal) | `func downloadAndInstallBinary() async throws` |
| 619 | fn | fetchLatestRelease | (private) | `private func fetchLatestRelease() async throws ...` |
| 640 | fn | findCompatibleAsset | (private) | `private func findCompatibleAsset(in release: Re...` |
| 665 | fn | downloadAsset | (private) | `private func downloadAsset(url: String) async t...` |
| 684 | fn | extractAndInstall | (private) | `private func extractAndInstall(data: Data, asse...` |
| 746 | fn | findBinaryInDirectory | (private) | `private func findBinaryInDirectory(_ directory:...` |
| 779 | fn | start | (internal) | `func start() async throws` |
| 911 | fn | stop | (internal) | `func stop()` |
| 967 | fn | startHealthMonitor | (private) | `private func startHealthMonitor()` |
| 981 | fn | stopHealthMonitor | (private) | `private func stopHealthMonitor()` |
| 986 | fn | performHealthCheck | (private) | `private func performHealthCheck() async` |
| 1049 | fn | cleanupOrphanProcesses | (private) | `private func cleanupOrphanProcesses() async` |
| 1112 | fn | terminateAuthProcess | (internal) | `func terminateAuthProcess()` |
| 1118 | fn | toggle | (internal) | `func toggle() async throws` |
| 1126 | fn | copyEndpointToClipboard | (internal) | `func copyEndpointToClipboard()` |
| 1131 | fn | revealInFinder | (internal) | `func revealInFinder()` |
| 1138 | enum | ProxyError | (internal) | `enum ProxyError` |
| 1169 | enum | AuthCommand | (internal) | `enum AuthCommand` |
| 1207 | struct | AuthCommandResult | (internal) | `struct AuthCommandResult` |
| 1213 | mod | extension CLIProxyManager | (internal) | - |
| 1214 | fn | runAuthCommand | (internal) | `func runAuthCommand(_ command: AuthCommand) asy...` |
| 1246 | fn | appendOutput | (internal) | `func appendOutput(_ str: String)` |
| 1250 | fn | tryResume | (internal) | `func tryResume() -> Bool` |
| 1261 | fn | safeResume | (internal) | `@Sendable func safeResume(_ result: AuthCommand...` |
| 1361 | mod | extension CLIProxyManager | (internal) | - |
| 1391 | fn | checkForUpgrade | (internal) | `func checkForUpgrade() async` |
| 1442 | fn | saveInstalledVersion | (private) | `private func saveInstalledVersion(_ version: St...` |
| 1450 | fn | fetchAvailableReleases | (internal) | `func fetchAvailableReleases(limit: Int = 10) as...` |
| 1472 | fn | versionInfo | (internal) | `func versionInfo(from release: GitHubRelease) -...` |
| 1478 | fn | fetchGitHubRelease | (private) | `private func fetchGitHubRelease(tag: String) as...` |
| 1500 | fn | findCompatibleAsset | (private) | `private func findCompatibleAsset(from release: ...` |
| 1533 | fn | performManagedUpgrade | (internal) | `func performManagedUpgrade(to version: ProxyVer...` |
| 1591 | fn | downloadAndInstallVersion | (private) | `private func downloadAndInstallVersion(_ versio...` |
| 1638 | fn | startDryRun | (private) | `private func startDryRun(version: String) async...` |
| 1709 | fn | promote | (private) | `private func promote(version: String) async throws` |
| 1744 | fn | rollback | (internal) | `func rollback() async throws` |
| 1777 | fn | stopTestProxy | (private) | `private func stopTestProxy() async` |
| 1806 | fn | stopTestProxySync | (private) | `private func stopTestProxySync()` |
| 1832 | fn | findUnusedPort | (private) | `private func findUnusedPort() throws -> UInt16` |
| 1842 | fn | isPortInUse | (private) | `private func isPortInUse(_ port: UInt16) -> Bool` |
| 1861 | fn | createTestConfig | (private) | `private func createTestConfig(port: UInt16) -> ...` |
| 1889 | fn | cleanupTestConfig | (private) | `private func cleanupTestConfig(_ configPath: St...` |
| 1897 | fn | isNewerVersion | (private) | `private func isNewerVersion(_ newer: String, th...` |
| 1900 | fn | parseVersion | (internal) | `func parseVersion(_ version: String) -> [Int]` |
| 1932 | fn | findPreviousVersion | (private) | `private func findPreviousVersion() -> String?` |
| 1945 | fn | migrateToVersionedStorage | (internal) | `func migrateToVersionedStorage() async throws` |

## Memory Markers

### 🟢 `NOTE` (line 222)

> Bridge mode default is registered in AppDelegate.applicationDidFinishLaunching()

### 🟢 `NOTE` (line 338)

> Changes take effect after proxy restart (CLIProxyAPI does not support live routing API)

### 🟢 `NOTE` (line 1425)

> Notification is handled by AtomFeedUpdateService polling

