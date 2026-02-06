# Quotio/Views/Screens/SettingsScreen.swift

[← Back to Module](../modules/Quotio-Views-Screens/MODULE.md) | [← Back to INDEX](../INDEX.md)

## Overview

- **Lines:** 3026
- **Language:** Swift
- **Symbols:** 60
- **Public symbols:** 0

## Symbol Table

| Line | Kind | Name | Visibility | Signature |
| ---- | ---- | ---- | ---------- | --------- |
| 9 | struct | SettingsScreen | (internal) | `struct SettingsScreen` |
| 108 | struct | OperatingModeSection | (internal) | `struct OperatingModeSection` |
| 173 | fn | handleModeSelection | (private) | `private func handleModeSelection(_ mode: Operat...` |
| 192 | fn | switchToMode | (private) | `private func switchToMode(_ mode: OperatingMode)` |
| 207 | struct | RemoteServerSection | (internal) | `struct RemoteServerSection` |
| 328 | fn | saveRemoteConfig | (private) | `private func saveRemoteConfig(_ config: RemoteC...` |
| 336 | fn | reconnect | (private) | `private func reconnect()` |
| 351 | struct | UnifiedProxySettingsSection | (internal) | `struct UnifiedProxySettingsSection` |
| 571 | fn | loadConfig | (private) | `private func loadConfig() async` |
| 612 | fn | saveProxyURL | (private) | `private func saveProxyURL() async` |
| 625 | fn | saveRoutingStrategy | (private) | `private func saveRoutingStrategy(_ strategy: St...` |
| 634 | fn | saveSwitchProject | (private) | `private func saveSwitchProject(_ enabled: Bool)...` |
| 643 | fn | saveSwitchPreviewModel | (private) | `private func saveSwitchPreviewModel(_ enabled: ...` |
| 652 | fn | saveRequestRetry | (private) | `private func saveRequestRetry(_ count: Int) async` |
| 661 | fn | saveMaxRetryInterval | (private) | `private func saveMaxRetryInterval(_ seconds: In...` |
| 670 | fn | saveLoggingToFile | (private) | `private func saveLoggingToFile(_ enabled: Bool)...` |
| 679 | fn | saveRequestLog | (private) | `private func saveRequestLog(_ enabled: Bool) async` |
| 688 | fn | saveDebugMode | (private) | `private func saveDebugMode(_ enabled: Bool) async` |
| 701 | struct | LocalProxyServerSection | (internal) | `struct LocalProxyServerSection` |
| 763 | struct | NetworkAccessSection | (internal) | `struct NetworkAccessSection` |
| 797 | struct | LocalPathsSection | (internal) | `struct LocalPathsSection` |
| 821 | struct | PathLabel | (internal) | `struct PathLabel` |
| 845 | struct | NotificationSettingsSection | (internal) | `struct NotificationSettingsSection` |
| 915 | struct | QuotaDisplaySettingsSection | (internal) | `struct QuotaDisplaySettingsSection` |
| 957 | struct | RefreshCadenceSettingsSection | (internal) | `struct RefreshCadenceSettingsSection` |
| 996 | struct | UpdateSettingsSection | (internal) | `struct UpdateSettingsSection` |
| 1038 | struct | ProxyUpdateSettingsSection | (internal) | `struct ProxyUpdateSettingsSection` |
| 1198 | fn | checkForUpdate | (private) | `private func checkForUpdate()` |
| 1212 | fn | performUpgrade | (private) | `private func performUpgrade(to version: ProxyVe...` |
| 1231 | struct | ProxyVersionManagerSheet | (internal) | `struct ProxyVersionManagerSheet` |
| 1390 | fn | sectionHeader | (private) | `@ViewBuilder   private func sectionHeader(_ tit...` |
| 1405 | fn | isVersionInstalled | (private) | `private func isVersionInstalled(_ version: Stri...` |
| 1409 | fn | refreshInstalledVersions | (private) | `private func refreshInstalledVersions()` |
| 1413 | fn | loadReleases | (private) | `private func loadReleases() async` |
| 1427 | fn | installVersion | (private) | `private func installVersion(_ release: GitHubRe...` |
| 1445 | fn | performInstall | (private) | `private func performInstall(_ release: GitHubRe...` |
| 1466 | fn | activateVersion | (private) | `private func activateVersion(_ version: String)` |
| 1484 | fn | deleteVersion | (private) | `private func deleteVersion(_ version: String)` |
| 1497 | struct | InstalledVersionRow | (private) | `struct InstalledVersionRow` |
| 1555 | struct | AvailableVersionRow | (private) | `struct AvailableVersionRow` |
| 1641 | fn | formatDate | (private) | `private func formatDate(_ isoString: String) ->...` |
| 1659 | struct | MenuBarSettingsSection | (internal) | `struct MenuBarSettingsSection` |
| 1800 | struct | AppearanceSettingsSection | (internal) | `struct AppearanceSettingsSection` |
| 1829 | struct | PrivacySettingsSection | (internal) | `struct PrivacySettingsSection` |
| 1851 | struct | GeneralSettingsTab | (internal) | `struct GeneralSettingsTab` |
| 1890 | struct | AboutTab | (internal) | `struct AboutTab` |
| 1917 | struct | AboutScreen | (internal) | `struct AboutScreen` |
| 2132 | struct | AboutUpdateSection | (internal) | `struct AboutUpdateSection` |
| 2188 | struct | AboutProxyUpdateSection | (internal) | `struct AboutProxyUpdateSection` |
| 2341 | fn | checkForUpdate | (private) | `private func checkForUpdate()` |
| 2355 | fn | performUpgrade | (private) | `private func performUpgrade(to version: ProxyVe...` |
| 2374 | struct | VersionBadge | (internal) | `struct VersionBadge` |
| 2426 | struct | AboutUpdateCard | (internal) | `struct AboutUpdateCard` |
| 2517 | struct | AboutProxyUpdateCard | (internal) | `struct AboutProxyUpdateCard` |
| 2691 | fn | checkForUpdate | (private) | `private func checkForUpdate()` |
| 2705 | fn | performUpgrade | (private) | `private func performUpgrade(to version: ProxyVe...` |
| 2724 | struct | LinkCard | (internal) | `struct LinkCard` |
| 2811 | struct | ManagementKeyRow | (internal) | `struct ManagementKeyRow` |
| 2905 | struct | LaunchAtLoginToggle | (internal) | `struct LaunchAtLoginToggle` |
| 2963 | struct | UsageDisplaySettingsSection | (internal) | `struct UsageDisplaySettingsSection` |

