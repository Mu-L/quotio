# Quotio/Services/Proxy/CLIProxyManager.swift

[← Back to Module](../modules/root/MODULE.md) | [← Back to INDEX](../INDEX.md)

## Overview

- **Lines:** 1948
- **Language:** Swift
- **Symbols:** 63
- **Public symbols:** 0

## Symbol Table

| Line | Kind | Name | Visibility | Signature |
| ---- | ---- | ---- | ---------- | --------- |
| 9 | class | CLIProxyManager | (internal) | `class CLIProxyManager` |
| 182 | method | init | (internal) | `init()` |
| 223 | fn | restartProxyIfRunning | (private) | `private func restartProxyIfRunning()` |
| 241 | fn | updateConfigValue | (private) | `private func updateConfigValue(pattern: String,...` |
| 261 | fn | updateConfigPort | (private) | `private func updateConfigPort(_ newPort: UInt16)` |
| 265 | fn | updateConfigHost | (private) | `private func updateConfigHost(_ host: String)` |
| 269 | fn | ensureApiKeyExistsInConfig | (private) | `private func ensureApiKeyExistsInConfig()` |
| 318 | fn | updateConfigLogging | (internal) | `func updateConfigLogging(enabled: Bool)` |
| 326 | fn | updateConfigRoutingStrategy | (internal) | `func updateConfigRoutingStrategy(_ strategy: St...` |
| 331 | fn | updateConfigProxyURL | (internal) | `func updateConfigProxyURL(_ url: String?)` |
| 359 | fn | applyBaseURLWorkaround | (internal) | `func applyBaseURLWorkaround()` |
| 388 | fn | removeBaseURLWorkaround | (internal) | `func removeBaseURLWorkaround()` |
| 430 | fn | ensureConfigExists | (private) | `private func ensureConfigExists()` |
| 464 | fn | syncSecretKeyInConfig | (private) | `private func syncSecretKeyInConfig()` |
| 480 | fn | regenerateManagementKey | (internal) | `func regenerateManagementKey() async throws` |
| 515 | fn | syncProxyURLInConfig | (private) | `private func syncProxyURLInConfig()` |
| 528 | fn | syncCustomProvidersToConfig | (private) | `private func syncCustomProvidersToConfig()` |
| 545 | fn | downloadAndInstallBinary | (internal) | `func downloadAndInstallBinary() async throws` |
| 606 | fn | fetchLatestRelease | (private) | `private func fetchLatestRelease() async throws ...` |
| 627 | fn | findCompatibleAsset | (private) | `private func findCompatibleAsset(in release: Re...` |
| 652 | fn | downloadAsset | (private) | `private func downloadAsset(url: String) async t...` |
| 671 | fn | extractAndInstall | (private) | `private func extractAndInstall(data: Data, asse...` |
| 733 | fn | findBinaryInDirectory | (private) | `private func findBinaryInDirectory(_ directory:...` |
| 766 | fn | start | (internal) | `func start() async throws` |
| 898 | fn | stop | (internal) | `func stop()` |
| 954 | fn | startHealthMonitor | (private) | `private func startHealthMonitor()` |
| 968 | fn | stopHealthMonitor | (private) | `private func stopHealthMonitor()` |
| 973 | fn | performHealthCheck | (private) | `private func performHealthCheck() async` |
| 1036 | fn | cleanupOrphanProcesses | (private) | `private func cleanupOrphanProcesses() async` |
| 1090 | fn | terminateAuthProcess | (internal) | `func terminateAuthProcess()` |
| 1096 | fn | toggle | (internal) | `func toggle() async throws` |
| 1104 | fn | copyEndpointToClipboard | (internal) | `func copyEndpointToClipboard()` |
| 1109 | fn | revealInFinder | (internal) | `func revealInFinder()` |
| 1116 | enum | ProxyError | (internal) | `enum ProxyError` |
| 1147 | enum | AuthCommand | (internal) | `enum AuthCommand` |
| 1185 | struct | AuthCommandResult | (internal) | `struct AuthCommandResult` |
| 1191 | mod | extension CLIProxyManager | (internal) | - |
| 1192 | fn | runAuthCommand | (internal) | `func runAuthCommand(_ command: AuthCommand) asy...` |
| 1224 | fn | appendOutput | (internal) | `func appendOutput(_ str: String)` |
| 1228 | fn | tryResume | (internal) | `func tryResume() -> Bool` |
| 1239 | fn | safeResume | (internal) | `@Sendable func safeResume(_ result: AuthCommand...` |
| 1339 | mod | extension CLIProxyManager | (internal) | - |
| 1369 | fn | checkForUpgrade | (internal) | `func checkForUpgrade() async` |
| 1420 | fn | saveInstalledVersion | (private) | `private func saveInstalledVersion(_ version: St...` |
| 1428 | fn | fetchAvailableReleases | (internal) | `func fetchAvailableReleases(limit: Int = 10) as...` |
| 1450 | fn | versionInfo | (internal) | `func versionInfo(from release: GitHubRelease) -...` |
| 1456 | fn | fetchGitHubRelease | (private) | `private func fetchGitHubRelease(tag: String) as...` |
| 1478 | fn | findCompatibleAsset | (private) | `private func findCompatibleAsset(from release: ...` |
| 1511 | fn | performManagedUpgrade | (internal) | `func performManagedUpgrade(to version: ProxyVer...` |
| 1569 | fn | downloadAndInstallVersion | (private) | `private func downloadAndInstallVersion(_ versio...` |
| 1616 | fn | startDryRun | (private) | `private func startDryRun(version: String) async...` |
| 1687 | fn | promote | (private) | `private func promote(version: String) async throws` |
| 1722 | fn | rollback | (internal) | `func rollback() async throws` |
| 1755 | fn | stopTestProxy | (private) | `private func stopTestProxy() async` |
| 1784 | fn | stopTestProxySync | (private) | `private func stopTestProxySync()` |
| 1810 | fn | findUnusedPort | (private) | `private func findUnusedPort() throws -> UInt16` |
| 1820 | fn | isPortInUse | (private) | `private func isPortInUse(_ port: UInt16) -> Bool` |
| 1839 | fn | createTestConfig | (private) | `private func createTestConfig(port: UInt16) -> ...` |
| 1867 | fn | cleanupTestConfig | (private) | `private func cleanupTestConfig(_ configPath: St...` |
| 1875 | fn | isNewerVersion | (private) | `private func isNewerVersion(_ newer: String, th...` |
| 1878 | fn | parseVersion | (internal) | `func parseVersion(_ version: String) -> [Int]` |
| 1910 | fn | findPreviousVersion | (private) | `private func findPreviousVersion() -> String?` |
| 1923 | fn | migrateToVersionedStorage | (internal) | `func migrateToVersionedStorage() async throws` |

## Memory Markers

### 🟢 `NOTE` (line 213)

> Bridge mode default is registered in AppDelegate.applicationDidFinishLaunching()

### 🟢 `NOTE` (line 325)

> Changes take effect after proxy restart (CLIProxyAPI does not support live routing API)

### 🟢 `NOTE` (line 1403)

> Notification is handled by AtomFeedUpdateService polling

