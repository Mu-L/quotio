# Quotio/ViewModels/QuotaViewModel.swift

[← Back to Module](../modules/root/MODULE.md) | [← Back to INDEX](../INDEX.md)

## Overview

- **Lines:** 1905
- **Language:** Swift
- **Symbols:** 92
- **Public symbols:** 0

## Symbol Table

| Line | Kind | Name | Visibility | Signature |
| ---- | ---- | ---- | ---------- | --------- |
| 11 | class | QuotaViewModel | (internal) | `class QuotaViewModel` |
| 130 | fn | loadDisabledAuthFiles | (private) | `private func loadDisabledAuthFiles() -> Set<Str...` |
| 136 | fn | saveDisabledAuthFiles | (private) | `private func saveDisabledAuthFiles(_ names: Set...` |
| 141 | fn | syncDisabledStatesToBackend | (private) | `private func syncDisabledStatesToBackend() async` |
| 160 | fn | notifyQuotaDataChanged | (private) | `private func notifyQuotaDataChanged()` |
| 163 | method | init | (internal) | `init()` |
| 173 | fn | setupProxyURLObserver | (private) | `private func setupProxyURLObserver()` |
| 189 | fn | normalizedProxyURL | (private) | `private func normalizedProxyURL(_ rawValue: Str...` |
| 201 | fn | updateProxyConfiguration | (internal) | `func updateProxyConfiguration() async` |
| 214 | fn | setupRefreshCadenceCallback | (private) | `private func setupRefreshCadenceCallback()` |
| 222 | fn | setupWarmupCallback | (private) | `private func setupWarmupCallback()` |
| 240 | fn | restartAutoRefresh | (private) | `private func restartAutoRefresh()` |
| 252 | fn | initialize | (internal) | `func initialize() async` |
| 262 | fn | initializeFullMode | (private) | `private func initializeFullMode() async` |
| 278 | fn | checkForProxyUpgrade | (private) | `private func checkForProxyUpgrade() async` |
| 283 | fn | initializeQuotaOnlyMode | (private) | `private func initializeQuotaOnlyMode() async` |
| 293 | fn | initializeRemoteMode | (private) | `private func initializeRemoteMode() async` |
| 321 | fn | setupRemoteAPIClient | (private) | `private func setupRemoteAPIClient(config: Remot...` |
| 329 | fn | reconnectRemote | (internal) | `func reconnectRemote() async` |
| 338 | fn | loadDirectAuthFiles | (internal) | `func loadDirectAuthFiles() async` |
| 344 | fn | refreshQuotasDirectly | (internal) | `func refreshQuotasDirectly() async` |
| 371 | fn | autoSelectMenuBarItems | (private) | `private func autoSelectMenuBarItems()` |
| 405 | fn | syncMenuBarSelection | (internal) | `func syncMenuBarSelection()` |
| 412 | fn | refreshClaudeCodeQuotasInternal | (private) | `private func refreshClaudeCodeQuotasInternal() ...` |
| 433 | fn | refreshCursorQuotasInternal | (private) | `private func refreshCursorQuotasInternal() async` |
| 444 | fn | refreshCodexCLIQuotasInternal | (private) | `private func refreshCodexCLIQuotasInternal() async` |
| 460 | fn | refreshGeminiCLIQuotasInternal | (private) | `private func refreshGeminiCLIQuotasInternal() a...` |
| 478 | fn | refreshGlmQuotasInternal | (private) | `private func refreshGlmQuotasInternal() async` |
| 488 | fn | refreshWarpQuotasInternal | (private) | `private func refreshWarpQuotasInternal() async` |
| 512 | fn | refreshTraeQuotasInternal | (private) | `private func refreshTraeQuotasInternal() async` |
| 522 | fn | refreshKiroQuotasInternal | (private) | `private func refreshKiroQuotasInternal() async` |
| 528 | fn | cleanName | (internal) | `func cleanName(_ name: String) -> String` |
| 578 | fn | startQuotaOnlyAutoRefresh | (private) | `private func startQuotaOnlyAutoRefresh()` |
| 596 | fn | startQuotaAutoRefreshWithoutProxy | (private) | `private func startQuotaAutoRefreshWithoutProxy()` |
| 615 | fn | isWarmupEnabled | (internal) | `func isWarmupEnabled(for provider: AIProvider, ...` |
| 619 | fn | warmupStatus | (internal) | `func warmupStatus(provider: AIProvider, account...` |
| 624 | fn | warmupNextRunDate | (internal) | `func warmupNextRunDate(provider: AIProvider, ac...` |
| 629 | fn | toggleWarmup | (internal) | `func toggleWarmup(for provider: AIProvider, acc...` |
| 638 | fn | setWarmupEnabled | (internal) | `func setWarmupEnabled(_ enabled: Bool, provider...` |
| 650 | fn | nextDailyRunDate | (private) | `private func nextDailyRunDate(minutes: Int, now...` |
| 661 | fn | restartWarmupScheduler | (private) | `private func restartWarmupScheduler()` |
| 694 | fn | runWarmupCycle | (private) | `private func runWarmupCycle() async` |
| 757 | fn | warmupAccount | (private) | `private func warmupAccount(provider: AIProvider...` |
| 802 | fn | warmupAccount | (private) | `private func warmupAccount(     provider: AIPro...` |
| 863 | fn | fetchWarmupModels | (private) | `private func fetchWarmupModels(     provider: A...` |
| 887 | fn | warmupAvailableModels | (internal) | `func warmupAvailableModels(provider: AIProvider...` |
| 900 | fn | warmupAuthInfo | (private) | `private func warmupAuthInfo(provider: AIProvide...` |
| 922 | fn | warmupTargets | (private) | `private func warmupTargets() -> [WarmupAccountKey]` |
| 936 | fn | updateWarmupStatus | (private) | `private func updateWarmupStatus(for key: Warmup...` |
| 965 | fn | startProxy | (internal) | `func startProxy() async` |
| 1002 | fn | stopProxy | (internal) | `func stopProxy()` |
| 1030 | fn | toggleProxy | (internal) | `func toggleProxy() async` |
| 1038 | fn | setupAPIClient | (private) | `private func setupAPIClient()` |
| 1045 | fn | startAutoRefresh | (private) | `private func startAutoRefresh()` |
| 1082 | fn | attemptProxyRecovery | (private) | `private func attemptProxyRecovery() async` |
| 1098 | fn | refreshData | (internal) | `func refreshData() async` |
| 1145 | fn | manualRefresh | (internal) | `func manualRefresh() async` |
| 1156 | fn | refreshAllQuotas | (internal) | `func refreshAllQuotas() async` |
| 1191 | fn | refreshQuotasUnified | (internal) | `func refreshQuotasUnified() async` |
| 1224 | fn | refreshAntigravityQuotasInternal | (private) | `private func refreshAntigravityQuotasInternal()...` |
| 1244 | fn | refreshAntigravityQuotasWithoutDetect | (private) | `private func refreshAntigravityQuotasWithoutDet...` |
| 1261 | fn | isAntigravityAccountActive | (internal) | `func isAntigravityAccountActive(email: String) ...` |
| 1266 | fn | switchAntigravityAccount | (internal) | `func switchAntigravityAccount(email: String) async` |
| 1278 | fn | beginAntigravitySwitch | (internal) | `func beginAntigravitySwitch(accountId: String, ...` |
| 1283 | fn | cancelAntigravitySwitch | (internal) | `func cancelAntigravitySwitch()` |
| 1288 | fn | dismissAntigravitySwitchResult | (internal) | `func dismissAntigravitySwitchResult()` |
| 1291 | fn | refreshOpenAIQuotasInternal | (private) | `private func refreshOpenAIQuotasInternal() async` |
| 1296 | fn | refreshCopilotQuotasInternal | (private) | `private func refreshCopilotQuotasInternal() async` |
| 1301 | fn | refreshQuotaForProvider | (internal) | `func refreshQuotaForProvider(_ provider: AIProv...` |
| 1336 | fn | refreshAutoDetectedProviders | (internal) | `func refreshAutoDetectedProviders() async` |
| 1343 | fn | startOAuth | (internal) | `func startOAuth(for provider: AIProvider, proje...` |
| 1385 | fn | startCopilotAuth | (private) | `private func startCopilotAuth() async` |
| 1402 | fn | startKiroAuth | (private) | `private func startKiroAuth(method: AuthCommand)...` |
| 1436 | fn | pollCopilotAuthCompletion | (private) | `private func pollCopilotAuthCompletion() async` |
| 1453 | fn | pollKiroAuthCompletion | (private) | `private func pollKiroAuthCompletion() async` |
| 1471 | fn | pollOAuthStatus | (private) | `private func pollOAuthStatus(state: String, pro...` |
| 1499 | fn | cancelOAuth | (internal) | `func cancelOAuth()` |
| 1503 | fn | deleteAuthFile | (internal) | `func deleteAuthFile(_ file: AuthFile) async` |
| 1539 | fn | toggleAuthFileDisabled | (internal) | `func toggleAuthFileDisabled(_ file: AuthFile) a...` |
| 1570 | fn | pruneMenuBarItems | (private) | `private func pruneMenuBarItems()` |
| 1606 | fn | importVertexServiceAccount | (internal) | `func importVertexServiceAccount(url: URL) async` |
| 1630 | fn | fetchAPIKeys | (internal) | `func fetchAPIKeys() async` |
| 1640 | fn | addAPIKey | (internal) | `func addAPIKey(_ key: String) async` |
| 1652 | fn | updateAPIKey | (internal) | `func updateAPIKey(old: String, new: String) async` |
| 1664 | fn | deleteAPIKey | (internal) | `func deleteAPIKey(_ key: String) async` |
| 1677 | fn | checkAccountStatusChanges | (private) | `private func checkAccountStatusChanges()` |
| 1698 | fn | checkQuotaNotifications | (internal) | `func checkQuotaNotifications()` |
| 1730 | fn | scanIDEsWithConsent | (internal) | `func scanIDEsWithConsent(options: IDEScanOption...` |
| 1799 | fn | savePersistedIDEQuotas | (private) | `private func savePersistedIDEQuotas()` |
| 1822 | fn | loadPersistedIDEQuotas | (private) | `private func loadPersistedIDEQuotas()` |
| 1884 | fn | shortenAccountKey | (private) | `private func shortenAccountKey(_ key: String) -...` |
| 1896 | struct | OAuthState | (internal) | `struct OAuthState` |

## Memory Markers

### 🟢 `NOTE` (line 270)

> checkForProxyUpgrade() is now called inside startProxy()

### 🟢 `NOTE` (line 343)

> Cursor and Trae are NOT auto-refreshed - user must use "Scan for IDEs" (issue #29)

### 🟢 `NOTE` (line 351)

> Cursor and Trae removed from auto-refresh to address privacy concerns (issue #29)

### 🟢 `NOTE` (line 1166)

> Cursor and Trae removed from auto-refresh (issue #29)

### 🟢 `NOTE` (line 1190)

> Cursor and Trae require explicit user scan (issue #29)

### 🟢 `NOTE` (line 1200)

> Cursor and Trae removed - require explicit scan (issue #29)

### 🟢 `NOTE` (line 1254)

> Don't call detectActiveAccount() here - already set by switch operation

