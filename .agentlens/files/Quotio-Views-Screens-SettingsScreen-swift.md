# Quotio/Views/Screens/SettingsScreen.swift

[← Back to Module](../modules/Quotio-Views-Screens/MODULE.md) | [← Back to INDEX](../INDEX.md)

## Overview

- **Lines:** 3028
- **Language:** Swift
- **Symbols:** 60
- **Public symbols:** 0

## Symbol Table

| Line | Kind | Name | Visibility | Signature |
| ---- | ---- | ---- | ---------- | --------- |
| 9 | struct | SettingsScreen | (internal) | `struct SettingsScreen` |
| 111 | struct | OperatingModeSection | (internal) | `struct OperatingModeSection` |
| 176 | fn | handleModeSelection | (private) | `private func handleModeSelection(_ mode: Operat...` |
| 195 | fn | switchToMode | (private) | `private func switchToMode(_ mode: OperatingMode)` |
| 210 | struct | RemoteServerSection | (internal) | `struct RemoteServerSection` |
| 330 | fn | saveRemoteConfig | (private) | `private func saveRemoteConfig(_ config: RemoteC...` |
| 338 | fn | reconnect | (private) | `private func reconnect()` |
| 353 | struct | UnifiedProxySettingsSection | (internal) | `struct UnifiedProxySettingsSection` |
| 573 | fn | loadConfig | (private) | `private func loadConfig() async` |
| 614 | fn | saveProxyURL | (private) | `private func saveProxyURL() async` |
| 627 | fn | saveRoutingStrategy | (private) | `private func saveRoutingStrategy(_ strategy: St...` |
| 636 | fn | saveSwitchProject | (private) | `private func saveSwitchProject(_ enabled: Bool)...` |
| 645 | fn | saveSwitchPreviewModel | (private) | `private func saveSwitchPreviewModel(_ enabled: ...` |
| 654 | fn | saveRequestRetry | (private) | `private func saveRequestRetry(_ count: Int) async` |
| 663 | fn | saveMaxRetryInterval | (private) | `private func saveMaxRetryInterval(_ seconds: In...` |
| 672 | fn | saveLoggingToFile | (private) | `private func saveLoggingToFile(_ enabled: Bool)...` |
| 681 | fn | saveRequestLog | (private) | `private func saveRequestLog(_ enabled: Bool) async` |
| 690 | fn | saveDebugMode | (private) | `private func saveDebugMode(_ enabled: Bool) async` |
| 703 | struct | LocalProxyServerSection | (internal) | `struct LocalProxyServerSection` |
| 765 | struct | NetworkAccessSection | (internal) | `struct NetworkAccessSection` |
| 799 | struct | LocalPathsSection | (internal) | `struct LocalPathsSection` |
| 823 | struct | PathLabel | (internal) | `struct PathLabel` |
| 847 | struct | NotificationSettingsSection | (internal) | `struct NotificationSettingsSection` |
| 917 | struct | QuotaDisplaySettingsSection | (internal) | `struct QuotaDisplaySettingsSection` |
| 959 | struct | RefreshCadenceSettingsSection | (internal) | `struct RefreshCadenceSettingsSection` |
| 998 | struct | UpdateSettingsSection | (internal) | `struct UpdateSettingsSection` |
| 1040 | struct | ProxyUpdateSettingsSection | (internal) | `struct ProxyUpdateSettingsSection` |
| 1200 | fn | checkForUpdate | (private) | `private func checkForUpdate()` |
| 1214 | fn | performUpgrade | (private) | `private func performUpgrade(to version: ProxyVe...` |
| 1233 | struct | ProxyVersionManagerSheet | (internal) | `struct ProxyVersionManagerSheet` |
| 1392 | fn | sectionHeader | (private) | `@ViewBuilder   private func sectionHeader(_ tit...` |
| 1407 | fn | isVersionInstalled | (private) | `private func isVersionInstalled(_ version: Stri...` |
| 1411 | fn | refreshInstalledVersions | (private) | `private func refreshInstalledVersions()` |
| 1415 | fn | loadReleases | (private) | `private func loadReleases() async` |
| 1429 | fn | installVersion | (private) | `private func installVersion(_ release: GitHubRe...` |
| 1447 | fn | performInstall | (private) | `private func performInstall(_ release: GitHubRe...` |
| 1468 | fn | activateVersion | (private) | `private func activateVersion(_ version: String)` |
| 1486 | fn | deleteVersion | (private) | `private func deleteVersion(_ version: String)` |
| 1499 | struct | InstalledVersionRow | (private) | `struct InstalledVersionRow` |
| 1557 | struct | AvailableVersionRow | (private) | `struct AvailableVersionRow` |
| 1643 | fn | formatDate | (private) | `private func formatDate(_ isoString: String) ->...` |
| 1661 | struct | MenuBarSettingsSection | (internal) | `struct MenuBarSettingsSection` |
| 1802 | struct | AppearanceSettingsSection | (internal) | `struct AppearanceSettingsSection` |
| 1831 | struct | PrivacySettingsSection | (internal) | `struct PrivacySettingsSection` |
| 1853 | struct | GeneralSettingsTab | (internal) | `struct GeneralSettingsTab` |
| 1892 | struct | AboutTab | (internal) | `struct AboutTab` |
| 1919 | struct | AboutScreen | (internal) | `struct AboutScreen` |
| 2134 | struct | AboutUpdateSection | (internal) | `struct AboutUpdateSection` |
| 2190 | struct | AboutProxyUpdateSection | (internal) | `struct AboutProxyUpdateSection` |
| 2343 | fn | checkForUpdate | (private) | `private func checkForUpdate()` |
| 2357 | fn | performUpgrade | (private) | `private func performUpgrade(to version: ProxyVe...` |
| 2376 | struct | VersionBadge | (internal) | `struct VersionBadge` |
| 2428 | struct | AboutUpdateCard | (internal) | `struct AboutUpdateCard` |
| 2519 | struct | AboutProxyUpdateCard | (internal) | `struct AboutProxyUpdateCard` |
| 2693 | fn | checkForUpdate | (private) | `private func checkForUpdate()` |
| 2707 | fn | performUpgrade | (private) | `private func performUpgrade(to version: ProxyVe...` |
| 2726 | struct | LinkCard | (internal) | `struct LinkCard` |
| 2813 | struct | ManagementKeyRow | (internal) | `struct ManagementKeyRow` |
| 2907 | struct | LaunchAtLoginToggle | (internal) | `struct LaunchAtLoginToggle` |
| 2965 | struct | UsageDisplaySettingsSection | (internal) | `struct UsageDisplaySettingsSection` |

