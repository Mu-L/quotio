# Quotio/Services/Proxy/CLIProxyManager.swift

[← Back to Module](../modules/root/MODULE.md) | [← Back to INDEX](../INDEX.md)

## Overview

- **Lines:** 1838
- **Language:** Swift
- **Symbols:** 60
- **Public symbols:** 0

## Symbol Table

| Line | Kind | Name | Visibility | Signature |
| ---- | ---- | ---- | ---------- | --------- |
| 9 | class | CLIProxyManager | (internal) | `class CLIProxyManager` |
| 181 | method | init | (internal) | `init()` |
| 219 | fn | updateConfigValue | (private) | `private func updateConfigValue(pattern: String,...` |
| 239 | fn | updateConfigPort | (private) | `private func updateConfigPort(_ newPort: UInt16)` |
| 243 | fn | updateConfigHost | (private) | `private func updateConfigHost(_ host: String)` |
| 247 | fn | ensureApiKeyExistsInConfig | (private) | `private func ensureApiKeyExistsInConfig()` |
| 296 | fn | updateConfigLogging | (internal) | `func updateConfigLogging(enabled: Bool)` |
| 303 | fn | updateConfigRoutingStrategy | (internal) | `func updateConfigRoutingStrategy(_ strategy: St...` |
| 307 | fn | updateConfigProxyURL | (internal) | `func updateConfigProxyURL(_ url: String?)` |
| 327 | fn | ensureConfigExists | (private) | `private func ensureConfigExists()` |
| 361 | fn | syncSecretKeyInConfig | (private) | `private func syncSecretKeyInConfig()` |
| 377 | fn | regenerateManagementKey | (internal) | `func regenerateManagementKey() async throws` |
| 412 | fn | syncProxyURLInConfig | (private) | `private func syncProxyURLInConfig()` |
| 425 | fn | syncCustomProvidersToConfig | (private) | `private func syncCustomProvidersToConfig()` |
| 442 | fn | downloadAndInstallBinary | (internal) | `func downloadAndInstallBinary() async throws` |
| 503 | fn | fetchLatestRelease | (private) | `private func fetchLatestRelease() async throws ...` |
| 524 | fn | findCompatibleAsset | (private) | `private func findCompatibleAsset(in release: Re...` |
| 549 | fn | downloadAsset | (private) | `private func downloadAsset(url: String) async t...` |
| 568 | fn | extractAndInstall | (private) | `private func extractAndInstall(data: Data, asse...` |
| 630 | fn | findBinaryInDirectory | (private) | `private func findBinaryInDirectory(_ directory:...` |
| 663 | fn | start | (internal) | `func start() async throws` |
| 795 | fn | stop | (internal) | `func stop()` |
| 851 | fn | startHealthMonitor | (private) | `private func startHealthMonitor()` |
| 865 | fn | stopHealthMonitor | (private) | `private func stopHealthMonitor()` |
| 870 | fn | performHealthCheck | (private) | `private func performHealthCheck() async` |
| 933 | fn | cleanupOrphanProcesses | (private) | `private func cleanupOrphanProcesses() async` |
| 987 | fn | terminateAuthProcess | (internal) | `func terminateAuthProcess()` |
| 993 | fn | toggle | (internal) | `func toggle() async throws` |
| 1001 | fn | copyEndpointToClipboard | (internal) | `func copyEndpointToClipboard()` |
| 1006 | fn | revealInFinder | (internal) | `func revealInFinder()` |
| 1013 | enum | ProxyError | (internal) | `enum ProxyError` |
| 1044 | enum | AuthCommand | (internal) | `enum AuthCommand` |
| 1082 | struct | AuthCommandResult | (internal) | `struct AuthCommandResult` |
| 1088 | mod | extension CLIProxyManager | (internal) | - |
| 1089 | fn | runAuthCommand | (internal) | `func runAuthCommand(_ command: AuthCommand) asy...` |
| 1121 | fn | appendOutput | (internal) | `func appendOutput(_ str: String)` |
| 1125 | fn | tryResume | (internal) | `func tryResume() -> Bool` |
| 1136 | fn | safeResume | (internal) | `@Sendable func safeResume(_ result: AuthCommand...` |
| 1236 | mod | extension CLIProxyManager | (internal) | - |
| 1266 | fn | checkForUpgrade | (internal) | `func checkForUpgrade() async` |
| 1314 | fn | saveInstalledVersion | (private) | `private func saveInstalledVersion(_ version: St...` |
| 1322 | fn | fetchAvailableReleases | (internal) | `func fetchAvailableReleases(limit: Int = 10) as...` |
| 1344 | fn | versionInfo | (internal) | `func versionInfo(from release: GitHubRelease) -...` |
| 1350 | fn | fetchGitHubRelease | (private) | `private func fetchGitHubRelease(tag: String) as...` |
| 1372 | fn | findCompatibleAsset | (private) | `private func findCompatibleAsset(from release: ...` |
| 1405 | fn | performManagedUpgrade | (internal) | `func performManagedUpgrade(to version: ProxyVer...` |
| 1459 | fn | downloadAndInstallVersion | (private) | `private func downloadAndInstallVersion(_ versio...` |
| 1506 | fn | startDryRun | (private) | `private func startDryRun(version: String) async...` |
| 1577 | fn | promote | (private) | `private func promote(version: String) async throws` |
| 1612 | fn | rollback | (internal) | `func rollback() async throws` |
| 1645 | fn | stopTestProxy | (private) | `private func stopTestProxy() async` |
| 1674 | fn | stopTestProxySync | (private) | `private func stopTestProxySync()` |
| 1700 | fn | findUnusedPort | (private) | `private func findUnusedPort() throws -> UInt16` |
| 1710 | fn | isPortInUse | (private) | `private func isPortInUse(_ port: UInt16) -> Bool` |
| 1729 | fn | createTestConfig | (private) | `private func createTestConfig(port: UInt16) -> ...` |
| 1757 | fn | cleanupTestConfig | (private) | `private func cleanupTestConfig(_ configPath: St...` |
| 1765 | fn | isNewerVersion | (private) | `private func isNewerVersion(_ newer: String, th...` |
| 1768 | fn | parseVersion | (internal) | `func parseVersion(_ version: String) -> [Int]` |
| 1800 | fn | findPreviousVersion | (private) | `private func findPreviousVersion() -> String?` |
| 1813 | fn | migrateToVersionedStorage | (internal) | `func migrateToVersionedStorage() async throws` |

## Memory Markers

### 🟢 `NOTE` (line 212)

> Bridge mode default is registered in AppDelegate.applicationDidFinishLaunching()

### 🟢 `NOTE` (line 302)

> Changes take effect after proxy restart (CLIProxyAPI does not support live routing API)

### 🟢 `NOTE` (line 1297)

> Notification is handled by AtomFeedUpdateService polling

