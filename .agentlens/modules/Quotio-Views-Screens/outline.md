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

## Quotio/Views/Screens/SettingsScreen.swift (3026 lines)

| Line | Kind | Name | Visibility |
| ---- | ---- | ---- | ---------- |
| 9 | struct | SettingsScreen | (internal) |
| 108 | struct | OperatingModeSection | (internal) |
| 173 | fn | handleModeSelection | (private) |
| 192 | fn | switchToMode | (private) |
| 207 | struct | RemoteServerSection | (internal) |
| 328 | fn | saveRemoteConfig | (private) |
| 336 | fn | reconnect | (private) |
| 351 | struct | UnifiedProxySettingsSection | (internal) |
| 571 | fn | loadConfig | (private) |
| 612 | fn | saveProxyURL | (private) |
| 625 | fn | saveRoutingStrategy | (private) |
| 634 | fn | saveSwitchProject | (private) |
| 643 | fn | saveSwitchPreviewModel | (private) |
| 652 | fn | saveRequestRetry | (private) |
| 661 | fn | saveMaxRetryInterval | (private) |
| 670 | fn | saveLoggingToFile | (private) |
| 679 | fn | saveRequestLog | (private) |
| 688 | fn | saveDebugMode | (private) |
| 701 | struct | LocalProxyServerSection | (internal) |
| 763 | struct | NetworkAccessSection | (internal) |
| 797 | struct | LocalPathsSection | (internal) |
| 821 | struct | PathLabel | (internal) |
| 845 | struct | NotificationSettingsSection | (internal) |
| 915 | struct | QuotaDisplaySettingsSection | (internal) |
| 957 | struct | RefreshCadenceSettingsSection | (internal) |
| 996 | struct | UpdateSettingsSection | (internal) |
| 1038 | struct | ProxyUpdateSettingsSection | (internal) |
| 1198 | fn | checkForUpdate | (private) |
| 1212 | fn | performUpgrade | (private) |
| 1231 | struct | ProxyVersionManagerSheet | (internal) |
| 1390 | fn | sectionHeader | (private) |
| 1405 | fn | isVersionInstalled | (private) |
| 1409 | fn | refreshInstalledVersions | (private) |
| 1413 | fn | loadReleases | (private) |
| 1427 | fn | installVersion | (private) |
| 1445 | fn | performInstall | (private) |
| 1466 | fn | activateVersion | (private) |
| 1484 | fn | deleteVersion | (private) |
| 1497 | struct | InstalledVersionRow | (private) |
| 1555 | struct | AvailableVersionRow | (private) |
| 1641 | fn | formatDate | (private) |
| 1659 | struct | MenuBarSettingsSection | (internal) |
| 1800 | struct | AppearanceSettingsSection | (internal) |
| 1829 | struct | PrivacySettingsSection | (internal) |
| 1851 | struct | GeneralSettingsTab | (internal) |
| 1890 | struct | AboutTab | (internal) |
| 1917 | struct | AboutScreen | (internal) |
| 2132 | struct | AboutUpdateSection | (internal) |
| 2188 | struct | AboutProxyUpdateSection | (internal) |
| 2341 | fn | checkForUpdate | (private) |
| 2355 | fn | performUpgrade | (private) |
| 2374 | struct | VersionBadge | (internal) |
| 2426 | struct | AboutUpdateCard | (internal) |
| 2517 | struct | AboutProxyUpdateCard | (internal) |
| 2691 | fn | checkForUpdate | (private) |
| 2705 | fn | performUpgrade | (private) |
| 2724 | struct | LinkCard | (internal) |
| 2811 | struct | ManagementKeyRow | (internal) |
| 2905 | struct | LaunchAtLoginToggle | (internal) |
| 2963 | struct | UsageDisplaySettingsSection | (internal) |

