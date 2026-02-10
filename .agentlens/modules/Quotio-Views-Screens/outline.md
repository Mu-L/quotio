# Outline

[← Back to MODULE](MODULE.md) | [← Back to INDEX](../../INDEX.md)

Symbol maps for 6 large files in this module.

## Quotio/Views/Screens/DashboardScreen.swift (1014 lines)

| Line | Kind | Name | Visibility |
| ---- | ---- | ---- | ---------- |
| 9 | struct | DashboardScreen | (internal) |
| 572 | fn | handleStepAction | (private) |
| 583 | fn | showProviderPicker | (private) |
| 607 | fn | showAgentPicker | (private) |
| 808 | struct | GettingStartedStep | (internal) |
| 817 | struct | GettingStartedStepRow | (internal) |
| 872 | struct | KPICard | (internal) |
| 900 | struct | ProviderChip | (internal) |
| 924 | struct | FlowLayout | (internal) |
| 938 | fn | layout | (private) |
| 966 | struct | QuotaProviderRow | (internal) |

## Quotio/Views/Screens/FallbackScreen.swift (528 lines)

| Line | Kind | Name | Visibility |
| ---- | ---- | ---- | ---------- |
| 8 | struct | FallbackScreen | (internal) |
| 105 | fn | loadModelsIfNeeded | (private) |
| 314 | struct | VirtualModelsEmptyState | (internal) |
| 356 | struct | VirtualModelRow | (internal) |
| 474 | struct | FallbackEntryRow | (internal) |

## Quotio/Views/Screens/LogsScreen.swift (541 lines)

| Line | Kind | Name | Visibility |
| ---- | ---- | ---- | ---------- |
| 8 | struct | LogsScreen | (internal) |
| 301 | struct | RequestRow | (internal) |
| 475 | fn | attemptOutcomeLabel | (private) |
| 486 | fn | attemptOutcomeColor | (private) |
| 501 | struct | StatItem | (internal) |
| 518 | struct | LogRow | (internal) |

## Quotio/Views/Screens/ProvidersScreen.swift (1008 lines)

| Line | Kind | Name | Visibility |
| ---- | ---- | ---- | ---------- |
| 16 | struct | ProvidersScreen | (internal) |
| 376 | fn | handleAddProvider | (private) |
| 394 | fn | deleteAccount | (private) |
| 424 | fn | toggleAccountDisabled | (private) |
| 434 | fn | handleEditGlmAccount | (private) |
| 441 | fn | handleEditWarpAccount | (private) |
| 449 | fn | syncCustomProvidersToConfig | (private) |
| 459 | struct | CustomProviderRow | (internal) |
| 560 | struct | MenuBarBadge | (internal) |
| 583 | class | TooltipWindow | (private) |
| 595 | method | init | (private) |
| 625 | fn | show | (internal) |
| 654 | fn | hide | (internal) |
| 660 | class | TooltipTrackingView | (private) |
| 662 | fn | updateTrackingAreas | (internal) |
| 673 | fn | mouseEntered | (internal) |
| 677 | fn | mouseExited | (internal) |
| 681 | fn | hitTest | (internal) |
| 687 | struct | NativeTooltipView | (private) |
| 689 | fn | makeNSView | (internal) |
| 695 | fn | updateNSView | (internal) |
| 701 | mod | extension View | (private) |
| 702 | fn | nativeTooltip | (internal) |
| 709 | struct | MenuBarHintView | (internal) |
| 724 | struct | OAuthSheet | (internal) |
| 850 | struct | OAuthStatusView | (private) |
| 987 | enum | CustomProviderSheetMode | (internal) |

## Quotio/Views/Screens/QuotaScreen.swift (1599 lines)

| Line | Kind | Name | Visibility |
| ---- | ---- | ---- | ---------- |
| 8 | struct | QuotaScreen | (internal) |
| 37 | fn | accountCount | (private) |
| 54 | fn | lowestQuotaPercent | (private) |
| 213 | struct | QuotaDisplayHelper | (private) |
| 215 | fn | statusColor | (internal) |
| 231 | fn | displayPercent | (internal) |
| 240 | struct | ProviderSegmentButton | (private) |
| 318 | struct | QuotaStatusDot | (private) |
| 337 | struct | ProviderQuotaView | (private) |
| 419 | struct | AccountInfo | (private) |
| 431 | struct | AccountQuotaCardV2 | (private) |
| 815 | fn | standardContentByStyle | (private) |
| 843 | struct | PlanBadgeV2Compact | (private) |
| 897 | struct | PlanBadgeV2 | (private) |
| 952 | struct | SubscriptionBadgeV2 | (private) |
| 993 | struct | AntigravityDisplayGroup | (private) |
| 1003 | struct | AntigravityGroupRow | (private) |
| 1080 | struct | AntigravityLowestBarLayout | (private) |
| 1099 | fn | displayPercent | (private) |
| 1161 | struct | AntigravityRingLayout | (private) |
| 1173 | fn | displayPercent | (private) |
| 1202 | struct | StandardLowestBarLayout | (private) |
| 1221 | fn | displayPercent | (private) |
| 1294 | struct | StandardRingLayout | (private) |
| 1306 | fn | displayPercent | (private) |
| 1341 | struct | AntigravityModelsDetailSheet | (private) |
| 1410 | struct | ModelDetailCard | (private) |
| 1477 | struct | UsageRowV2 | (private) |
| 1565 | struct | QuotaLoadingView | (private) |

## Quotio/Views/Screens/SettingsScreen.swift (3028 lines)

| Line | Kind | Name | Visibility |
| ---- | ---- | ---- | ---------- |
| 9 | struct | SettingsScreen | (internal) |
| 111 | struct | OperatingModeSection | (internal) |
| 176 | fn | handleModeSelection | (private) |
| 195 | fn | switchToMode | (private) |
| 210 | struct | RemoteServerSection | (internal) |
| 330 | fn | saveRemoteConfig | (private) |
| 338 | fn | reconnect | (private) |
| 353 | struct | UnifiedProxySettingsSection | (internal) |
| 573 | fn | loadConfig | (private) |
| 614 | fn | saveProxyURL | (private) |
| 627 | fn | saveRoutingStrategy | (private) |
| 636 | fn | saveSwitchProject | (private) |
| 645 | fn | saveSwitchPreviewModel | (private) |
| 654 | fn | saveRequestRetry | (private) |
| 663 | fn | saveMaxRetryInterval | (private) |
| 672 | fn | saveLoggingToFile | (private) |
| 681 | fn | saveRequestLog | (private) |
| 690 | fn | saveDebugMode | (private) |
| 703 | struct | LocalProxyServerSection | (internal) |
| 765 | struct | NetworkAccessSection | (internal) |
| 799 | struct | LocalPathsSection | (internal) |
| 823 | struct | PathLabel | (internal) |
| 847 | struct | NotificationSettingsSection | (internal) |
| 917 | struct | QuotaDisplaySettingsSection | (internal) |
| 959 | struct | RefreshCadenceSettingsSection | (internal) |
| 998 | struct | UpdateSettingsSection | (internal) |
| 1040 | struct | ProxyUpdateSettingsSection | (internal) |
| 1200 | fn | checkForUpdate | (private) |
| 1214 | fn | performUpgrade | (private) |
| 1233 | struct | ProxyVersionManagerSheet | (internal) |
| 1392 | fn | sectionHeader | (private) |
| 1407 | fn | isVersionInstalled | (private) |
| 1411 | fn | refreshInstalledVersions | (private) |
| 1415 | fn | loadReleases | (private) |
| 1429 | fn | installVersion | (private) |
| 1447 | fn | performInstall | (private) |
| 1468 | fn | activateVersion | (private) |
| 1486 | fn | deleteVersion | (private) |
| 1499 | struct | InstalledVersionRow | (private) |
| 1557 | struct | AvailableVersionRow | (private) |
| 1643 | fn | formatDate | (private) |
| 1661 | struct | MenuBarSettingsSection | (internal) |
| 1802 | struct | AppearanceSettingsSection | (internal) |
| 1831 | struct | PrivacySettingsSection | (internal) |
| 1853 | struct | GeneralSettingsTab | (internal) |
| 1892 | struct | AboutTab | (internal) |
| 1919 | struct | AboutScreen | (internal) |
| 2134 | struct | AboutUpdateSection | (internal) |
| 2190 | struct | AboutProxyUpdateSection | (internal) |
| 2343 | fn | checkForUpdate | (private) |
| 2357 | fn | performUpgrade | (private) |
| 2376 | struct | VersionBadge | (internal) |
| 2428 | struct | AboutUpdateCard | (internal) |
| 2519 | struct | AboutProxyUpdateCard | (internal) |
| 2693 | fn | checkForUpdate | (private) |
| 2707 | fn | performUpgrade | (private) |
| 2726 | struct | LinkCard | (internal) |
| 2813 | struct | ManagementKeyRow | (internal) |
| 2907 | struct | LaunchAtLoginToggle | (internal) |
| 2965 | struct | UsageDisplaySettingsSection | (internal) |

