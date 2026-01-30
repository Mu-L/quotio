# Quotio/ViewModels/QuotaViewModel.swift

[← Back to Module](../modules/root/MODULE.md) | [← Back to INDEX](../INDEX.md)

## Overview

- **Lines:** 1825
- **Language:** Swift
- **Symbols:** 88
- **Public symbols:** 0

## Symbol Table

| Line | Kind | Name | Visibility | Signature |
| ---- | ---- | ---- | ---------- | --------- |
| 11 | class | QuotaViewModel | (internal) | `class QuotaViewModel` |
| 126 | fn | notifyQuotaDataChanged | (private) | `private func notifyQuotaDataChanged()` |
| 129 | method | init | (internal) | `init()` |
| 139 | fn | setupProxyURLObserver | (private) | `private func setupProxyURLObserver()` |
| 155 | fn | normalizedProxyURL | (private) | `private func normalizedProxyURL(_ rawValue: Str...` |
| 167 | fn | updateProxyConfiguration | (internal) | `func updateProxyConfiguration() async` |
| 180 | fn | setupRefreshCadenceCallback | (private) | `private func setupRefreshCadenceCallback()` |
| 188 | fn | setupWarmupCallback | (private) | `private func setupWarmupCallback()` |
| 206 | fn | restartAutoRefresh | (private) | `private func restartAutoRefresh()` |
| 218 | fn | initialize | (internal) | `func initialize() async` |
| 228 | fn | initializeFullMode | (private) | `private func initializeFullMode() async` |
| 244 | fn | checkForProxyUpgrade | (private) | `private func checkForProxyUpgrade() async` |
| 249 | fn | initializeQuotaOnlyMode | (private) | `private func initializeQuotaOnlyMode() async` |
| 259 | fn | initializeRemoteMode | (private) | `private func initializeRemoteMode() async` |
| 287 | fn | setupRemoteAPIClient | (private) | `private func setupRemoteAPIClient(config: Remot...` |
| 295 | fn | reconnectRemote | (internal) | `func reconnectRemote() async` |
| 304 | fn | loadDirectAuthFiles | (internal) | `func loadDirectAuthFiles() async` |
| 310 | fn | refreshQuotasDirectly | (internal) | `func refreshQuotasDirectly() async` |
| 337 | fn | autoSelectMenuBarItems | (private) | `private func autoSelectMenuBarItems()` |
| 371 | fn | syncMenuBarSelection | (internal) | `func syncMenuBarSelection()` |
| 378 | fn | refreshClaudeCodeQuotasInternal | (private) | `private func refreshClaudeCodeQuotasInternal() ...` |
| 399 | fn | refreshCursorQuotasInternal | (private) | `private func refreshCursorQuotasInternal() async` |
| 410 | fn | refreshCodexCLIQuotasInternal | (private) | `private func refreshCodexCLIQuotasInternal() async` |
| 430 | fn | refreshGeminiCLIQuotasInternal | (private) | `private func refreshGeminiCLIQuotasInternal() a...` |
| 448 | fn | refreshGlmQuotasInternal | (private) | `private func refreshGlmQuotasInternal() async` |
| 458 | fn | refreshWarpQuotasInternal | (private) | `private func refreshWarpQuotasInternal() async` |
| 482 | fn | refreshTraeQuotasInternal | (private) | `private func refreshTraeQuotasInternal() async` |
| 492 | fn | refreshKiroQuotasInternal | (private) | `private func refreshKiroQuotasInternal() async` |
| 498 | fn | cleanName | (internal) | `func cleanName(_ name: String) -> String` |
| 548 | fn | startQuotaOnlyAutoRefresh | (private) | `private func startQuotaOnlyAutoRefresh()` |
| 566 | fn | startQuotaAutoRefreshWithoutProxy | (private) | `private func startQuotaAutoRefreshWithoutProxy()` |
| 585 | fn | isWarmupEnabled | (internal) | `func isWarmupEnabled(for provider: AIProvider, ...` |
| 589 | fn | warmupStatus | (internal) | `func warmupStatus(provider: AIProvider, account...` |
| 594 | fn | warmupNextRunDate | (internal) | `func warmupNextRunDate(provider: AIProvider, ac...` |
| 599 | fn | toggleWarmup | (internal) | `func toggleWarmup(for provider: AIProvider, acc...` |
| 608 | fn | setWarmupEnabled | (internal) | `func setWarmupEnabled(_ enabled: Bool, provider...` |
| 620 | fn | nextDailyRunDate | (private) | `private func nextDailyRunDate(minutes: Int, now...` |
| 631 | fn | restartWarmupScheduler | (private) | `private func restartWarmupScheduler()` |
| 664 | fn | runWarmupCycle | (private) | `private func runWarmupCycle() async` |
| 727 | fn | warmupAccount | (private) | `private func warmupAccount(provider: AIProvider...` |
| 772 | fn | warmupAccount | (private) | `private func warmupAccount(     provider: AIPro...` |
| 833 | fn | fetchWarmupModels | (private) | `private func fetchWarmupModels(     provider: A...` |
| 857 | fn | warmupAvailableModels | (internal) | `func warmupAvailableModels(provider: AIProvider...` |
| 870 | fn | warmupAuthInfo | (private) | `private func warmupAuthInfo(provider: AIProvide...` |
| 892 | fn | warmupTargets | (private) | `private func warmupTargets() -> [WarmupAccountKey]` |
| 906 | fn | updateWarmupStatus | (private) | `private func updateWarmupStatus(for key: Warmup...` |
| 935 | fn | startProxy | (internal) | `func startProxy() async` |
| 967 | fn | stopProxy | (internal) | `func stopProxy()` |
| 995 | fn | toggleProxy | (internal) | `func toggleProxy() async` |
| 1003 | fn | setupAPIClient | (private) | `private func setupAPIClient()` |
| 1010 | fn | startAutoRefresh | (private) | `private func startAutoRefresh()` |
| 1047 | fn | attemptProxyRecovery | (private) | `private func attemptProxyRecovery() async` |
| 1063 | fn | refreshData | (internal) | `func refreshData() async` |
| 1110 | fn | manualRefresh | (internal) | `func manualRefresh() async` |
| 1121 | fn | refreshAllQuotas | (internal) | `func refreshAllQuotas() async` |
| 1151 | fn | refreshQuotasUnified | (internal) | `func refreshQuotasUnified() async` |
| 1183 | fn | refreshAntigravityQuotasInternal | (private) | `private func refreshAntigravityQuotasInternal()...` |
| 1203 | fn | refreshAntigravityQuotasWithoutDetect | (private) | `private func refreshAntigravityQuotasWithoutDet...` |
| 1220 | fn | isAntigravityAccountActive | (internal) | `func isAntigravityAccountActive(email: String) ...` |
| 1225 | fn | switchAntigravityAccount | (internal) | `func switchAntigravityAccount(email: String) async` |
| 1237 | fn | beginAntigravitySwitch | (internal) | `func beginAntigravitySwitch(accountId: String, ...` |
| 1242 | fn | cancelAntigravitySwitch | (internal) | `func cancelAntigravitySwitch()` |
| 1247 | fn | dismissAntigravitySwitchResult | (internal) | `func dismissAntigravitySwitchResult()` |
| 1250 | fn | refreshOpenAIQuotasInternal | (private) | `private func refreshOpenAIQuotasInternal() async` |
| 1255 | fn | refreshCopilotQuotasInternal | (private) | `private func refreshCopilotQuotasInternal() async` |
| 1260 | fn | refreshQuotaForProvider | (internal) | `func refreshQuotaForProvider(_ provider: AIProv...` |
| 1295 | fn | refreshAutoDetectedProviders | (internal) | `func refreshAutoDetectedProviders() async` |
| 1302 | fn | startOAuth | (internal) | `func startOAuth(for provider: AIProvider, proje...` |
| 1344 | fn | startCopilotAuth | (private) | `private func startCopilotAuth() async` |
| 1361 | fn | startKiroAuth | (private) | `private func startKiroAuth(method: AuthCommand)...` |
| 1395 | fn | pollCopilotAuthCompletion | (private) | `private func pollCopilotAuthCompletion() async` |
| 1412 | fn | pollKiroAuthCompletion | (private) | `private func pollKiroAuthCompletion() async` |
| 1430 | fn | pollOAuthStatus | (private) | `private func pollOAuthStatus(state: String, pro...` |
| 1458 | fn | cancelOAuth | (internal) | `func cancelOAuth()` |
| 1462 | fn | deleteAuthFile | (internal) | `func deleteAuthFile(_ file: AuthFile) async` |
| 1490 | fn | pruneMenuBarItems | (private) | `private func pruneMenuBarItems()` |
| 1526 | fn | importVertexServiceAccount | (internal) | `func importVertexServiceAccount(url: URL) async` |
| 1550 | fn | fetchAPIKeys | (internal) | `func fetchAPIKeys() async` |
| 1560 | fn | addAPIKey | (internal) | `func addAPIKey(_ key: String) async` |
| 1572 | fn | updateAPIKey | (internal) | `func updateAPIKey(old: String, new: String) async` |
| 1584 | fn | deleteAPIKey | (internal) | `func deleteAPIKey(_ key: String) async` |
| 1597 | fn | checkAccountStatusChanges | (private) | `private func checkAccountStatusChanges()` |
| 1618 | fn | checkQuotaNotifications | (internal) | `func checkQuotaNotifications()` |
| 1650 | fn | scanIDEsWithConsent | (internal) | `func scanIDEsWithConsent(options: IDEScanOption...` |
| 1719 | fn | savePersistedIDEQuotas | (private) | `private func savePersistedIDEQuotas()` |
| 1742 | fn | loadPersistedIDEQuotas | (private) | `private func loadPersistedIDEQuotas()` |
| 1804 | fn | shortenAccountKey | (private) | `private func shortenAccountKey(_ key: String) -...` |
| 1816 | struct | OAuthState | (internal) | `struct OAuthState` |

## Memory Markers

### 🟢 `NOTE` (line 236)

> checkForProxyUpgrade() is now called inside startProxy()

### 🟢 `NOTE` (line 309)

> Cursor and Trae are NOT auto-refreshed - user must use "Scan for IDEs" (issue #29)

### 🟢 `NOTE` (line 317)

> Cursor and Trae removed from auto-refresh to address privacy concerns (issue #29)

### 🟢 `NOTE` (line 1128)

> Cursor and Trae removed from auto-refresh (issue #29)

### 🟢 `NOTE` (line 1150)

> Cursor and Trae require explicit user scan (issue #29)

### 🟢 `NOTE` (line 1159)

> Cursor and Trae removed - require explicit scan (issue #29)

### 🟢 `NOTE` (line 1213)

> Don't call detectActiveAccount() here - already set by switch operation

