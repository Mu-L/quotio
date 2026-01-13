# Quotio/Views/Screens/SettingsScreen.swift

[← Back to Module](../modules/Quotio-Views-Screens/MODULE.md) | [← Back to INDEX](../INDEX.md)

## Overview

- **Lines:** 2857
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
| 547 | fn | loadConfig | (private) | `private func loadConfig() async` |
| 578 | fn | saveProxyURL | (private) | `private func saveProxyURL() async` |
| 591 | fn | saveRoutingStrategy | (private) | `private func saveRoutingStrategy(_ strategy: St...` |
| 600 | fn | saveSwitchProject | (private) | `private func saveSwitchProject(_ enabled: Bool)...` |
| 609 | fn | saveSwitchPreviewModel | (private) | `private func saveSwitchPreviewModel(_ enabled: ...` |
| 618 | fn | saveRequestRetry | (private) | `private func saveRequestRetry(_ count: Int) async` |
| 627 | fn | saveMaxRetryInterval | (private) | `private func saveMaxRetryInterval(_ seconds: In...` |
| 636 | fn | saveLoggingToFile | (private) | `private func saveLoggingToFile(_ enabled: Bool)...` |
| 645 | fn | saveRequestLog | (private) | `private func saveRequestLog(_ enabled: Bool) async` |
| 654 | fn | saveDebugMode | (private) | `private func saveDebugMode(_ enabled: Bool) async` |
| 667 | struct | LocalProxyServerSection | (internal) | `struct LocalProxyServerSection` |
| 729 | struct | NetworkAccessSection | (internal) | `struct NetworkAccessSection` |
| 763 | struct | LocalPathsSection | (internal) | `struct LocalPathsSection` |
| 787 | struct | PathLabel | (internal) | `struct PathLabel` |
| 811 | struct | NotificationSettingsSection | (internal) | `struct NotificationSettingsSection` |
| 881 | struct | QuotaDisplaySettingsSection | (internal) | `struct QuotaDisplaySettingsSection` |
| 923 | struct | RefreshCadenceSettingsSection | (internal) | `struct RefreshCadenceSettingsSection` |
| 962 | struct | UpdateSettingsSection | (internal) | `struct UpdateSettingsSection` |
| 1004 | struct | ProxyUpdateSettingsSection | (internal) | `struct ProxyUpdateSettingsSection` |
| 1134 | fn | checkForUpdate | (private) | `private func checkForUpdate()` |
| 1144 | fn | performUpgrade | (private) | `private func performUpgrade(to version: ProxyVe...` |
| 1163 | struct | ProxyVersionManagerSheet | (internal) | `struct ProxyVersionManagerSheet` |
| 1322 | fn | sectionHeader | (private) | `@ViewBuilder   private func sectionHeader(_ tit...` |
| 1337 | fn | isVersionInstalled | (private) | `private func isVersionInstalled(_ version: Stri...` |
| 1341 | fn | refreshInstalledVersions | (private) | `private func refreshInstalledVersions()` |
| 1345 | fn | loadReleases | (private) | `private func loadReleases() async` |
| 1359 | fn | installVersion | (private) | `private func installVersion(_ release: GitHubRe...` |
| 1377 | fn | performInstall | (private) | `private func performInstall(_ release: GitHubRe...` |
| 1398 | fn | activateVersion | (private) | `private func activateVersion(_ version: String)` |
| 1416 | fn | deleteVersion | (private) | `private func deleteVersion(_ version: String)` |
| 1429 | struct | InstalledVersionRow | (private) | `struct InstalledVersionRow` |
| 1487 | struct | AvailableVersionRow | (private) | `struct AvailableVersionRow` |
| 1573 | fn | formatDate | (private) | `private func formatDate(_ isoString: String) ->...` |
| 1591 | struct | MenuBarSettingsSection | (internal) | `struct MenuBarSettingsSection` |
| 1673 | struct | AppearanceSettingsSection | (internal) | `struct AppearanceSettingsSection` |
| 1702 | struct | PrivacySettingsSection | (internal) | `struct PrivacySettingsSection` |
| 1724 | struct | GeneralSettingsTab | (internal) | `struct GeneralSettingsTab` |
| 1763 | struct | AboutTab | (internal) | `struct AboutTab` |
| 1790 | struct | AboutScreen | (internal) | `struct AboutScreen` |
| 2005 | struct | AboutUpdateSection | (internal) | `struct AboutUpdateSection` |
| 2061 | struct | AboutProxyUpdateSection | (internal) | `struct AboutProxyUpdateSection` |
| 2197 | fn | checkForUpdate | (private) | `private func checkForUpdate()` |
| 2207 | fn | performUpgrade | (private) | `private func performUpgrade(to version: ProxyVe...` |
| 2226 | struct | VersionBadge | (internal) | `struct VersionBadge` |
| 2278 | struct | AboutUpdateCard | (internal) | `struct AboutUpdateCard` |
| 2369 | struct | AboutProxyUpdateCard | (internal) | `struct AboutProxyUpdateCard` |
| 2526 | fn | checkForUpdate | (private) | `private func checkForUpdate()` |
| 2536 | fn | performUpgrade | (private) | `private func performUpgrade(to version: ProxyVe...` |
| 2555 | struct | LinkCard | (internal) | `struct LinkCard` |
| 2642 | struct | ManagementKeyRow | (internal) | `struct ManagementKeyRow` |
| 2736 | struct | LaunchAtLoginToggle | (internal) | `struct LaunchAtLoginToggle` |
| 2794 | struct | UsageDisplaySettingsSection | (internal) | `struct UsageDisplaySettingsSection` |

