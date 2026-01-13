# Quotio/Views/Screens/SettingsScreen.swift

[← Back to Module](../modules/Quotio-Views-Screens/MODULE.md) | [← Back to INDEX](../INDEX.md)

## Overview

- **Lines:** 2870
- **Language:** Swift
- **Symbols:** 60
- **Public symbols:** 0

## Symbol Table

| Line | Kind | Name | Visibility | Signature |
| ---- | ---- | ---- | ---------- | --------- |
| 9 | struct | SettingsScreen | (internal) | `struct SettingsScreen` |
| 93 | struct | OperatingModeSection | (internal) | `struct OperatingModeSection` |
| 158 | fn | handleModeSelection | (private) | `private func handleModeSelection(_ mode: Operat...` |
| 177 | fn | switchToMode | (private) | `private func switchToMode(_ mode: OperatingMode)` |
| 192 | struct | RemoteServerSection | (internal) | `struct RemoteServerSection` |
| 313 | fn | saveRemoteConfig | (private) | `private func saveRemoteConfig(_ config: RemoteC...` |
| 321 | fn | reconnect | (private) | `private func reconnect()` |
| 336 | struct | UnifiedProxySettingsSection | (internal) | `struct UnifiedProxySettingsSection` |
| 556 | fn | loadConfig | (private) | `private func loadConfig() async` |
| 591 | fn | saveProxyURL | (private) | `private func saveProxyURL() async` |
| 604 | fn | saveRoutingStrategy | (private) | `private func saveRoutingStrategy(_ strategy: St...` |
| 613 | fn | saveSwitchProject | (private) | `private func saveSwitchProject(_ enabled: Bool)...` |
| 622 | fn | saveSwitchPreviewModel | (private) | `private func saveSwitchPreviewModel(_ enabled: ...` |
| 631 | fn | saveRequestRetry | (private) | `private func saveRequestRetry(_ count: Int) async` |
| 640 | fn | saveMaxRetryInterval | (private) | `private func saveMaxRetryInterval(_ seconds: In...` |
| 649 | fn | saveLoggingToFile | (private) | `private func saveLoggingToFile(_ enabled: Bool)...` |
| 658 | fn | saveRequestLog | (private) | `private func saveRequestLog(_ enabled: Bool) async` |
| 667 | fn | saveDebugMode | (private) | `private func saveDebugMode(_ enabled: Bool) async` |
| 680 | struct | LocalProxyServerSection | (internal) | `struct LocalProxyServerSection` |
| 742 | struct | NetworkAccessSection | (internal) | `struct NetworkAccessSection` |
| 776 | struct | LocalPathsSection | (internal) | `struct LocalPathsSection` |
| 800 | struct | PathLabel | (internal) | `struct PathLabel` |
| 824 | struct | NotificationSettingsSection | (internal) | `struct NotificationSettingsSection` |
| 894 | struct | QuotaDisplaySettingsSection | (internal) | `struct QuotaDisplaySettingsSection` |
| 936 | struct | RefreshCadenceSettingsSection | (internal) | `struct RefreshCadenceSettingsSection` |
| 975 | struct | UpdateSettingsSection | (internal) | `struct UpdateSettingsSection` |
| 1017 | struct | ProxyUpdateSettingsSection | (internal) | `struct ProxyUpdateSettingsSection` |
| 1147 | fn | checkForUpdate | (private) | `private func checkForUpdate()` |
| 1157 | fn | performUpgrade | (private) | `private func performUpgrade(to version: ProxyVe...` |
| 1176 | struct | ProxyVersionManagerSheet | (internal) | `struct ProxyVersionManagerSheet` |
| 1335 | fn | sectionHeader | (private) | `@ViewBuilder   private func sectionHeader(_ tit...` |
| 1350 | fn | isVersionInstalled | (private) | `private func isVersionInstalled(_ version: Stri...` |
| 1354 | fn | refreshInstalledVersions | (private) | `private func refreshInstalledVersions()` |
| 1358 | fn | loadReleases | (private) | `private func loadReleases() async` |
| 1372 | fn | installVersion | (private) | `private func installVersion(_ release: GitHubRe...` |
| 1390 | fn | performInstall | (private) | `private func performInstall(_ release: GitHubRe...` |
| 1411 | fn | activateVersion | (private) | `private func activateVersion(_ version: String)` |
| 1429 | fn | deleteVersion | (private) | `private func deleteVersion(_ version: String)` |
| 1442 | struct | InstalledVersionRow | (private) | `struct InstalledVersionRow` |
| 1500 | struct | AvailableVersionRow | (private) | `struct AvailableVersionRow` |
| 1586 | fn | formatDate | (private) | `private func formatDate(_ isoString: String) ->...` |
| 1604 | struct | MenuBarSettingsSection | (internal) | `struct MenuBarSettingsSection` |
| 1686 | struct | AppearanceSettingsSection | (internal) | `struct AppearanceSettingsSection` |
| 1715 | struct | PrivacySettingsSection | (internal) | `struct PrivacySettingsSection` |
| 1737 | struct | GeneralSettingsTab | (internal) | `struct GeneralSettingsTab` |
| 1776 | struct | AboutTab | (internal) | `struct AboutTab` |
| 1803 | struct | AboutScreen | (internal) | `struct AboutScreen` |
| 2018 | struct | AboutUpdateSection | (internal) | `struct AboutUpdateSection` |
| 2074 | struct | AboutProxyUpdateSection | (internal) | `struct AboutProxyUpdateSection` |
| 2210 | fn | checkForUpdate | (private) | `private func checkForUpdate()` |
| 2220 | fn | performUpgrade | (private) | `private func performUpgrade(to version: ProxyVe...` |
| 2239 | struct | VersionBadge | (internal) | `struct VersionBadge` |
| 2291 | struct | AboutUpdateCard | (internal) | `struct AboutUpdateCard` |
| 2382 | struct | AboutProxyUpdateCard | (internal) | `struct AboutProxyUpdateCard` |
| 2539 | fn | checkForUpdate | (private) | `private func checkForUpdate()` |
| 2549 | fn | performUpgrade | (private) | `private func performUpgrade(to version: ProxyVe...` |
| 2568 | struct | LinkCard | (internal) | `struct LinkCard` |
| 2655 | struct | ManagementKeyRow | (internal) | `struct ManagementKeyRow` |
| 2749 | struct | LaunchAtLoginToggle | (internal) | `struct LaunchAtLoginToggle` |
| 2807 | struct | UsageDisplaySettingsSection | (internal) | `struct UsageDisplaySettingsSection` |

