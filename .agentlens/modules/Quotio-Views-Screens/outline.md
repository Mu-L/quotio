# Outline

[← Back to MODULE](MODULE.md) | [← Back to INDEX](../../INDEX.md)

Symbol maps for 5 large files in this module.

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

## Quotio/Views/Screens/FallbackScreen.swift (526 lines)

| Line | Kind | Name | Visibility |
| ---- | ---- | ---- | ---------- |
| 8 | struct | FallbackScreen | (internal) |
| 103 | fn | loadModelsIfNeeded | (private) |
| 312 | struct | VirtualModelsEmptyState | (internal) |
| 354 | struct | VirtualModelRow | (internal) |
| 472 | struct | FallbackEntryRow | (internal) |

## Quotio/Views/Screens/ProvidersScreen.swift (916 lines)

| Line | Kind | Name | Visibility |
| ---- | ---- | ---- | ---------- |
| 16 | struct | ProvidersScreen | (internal) |
| 338 | fn | handleAddProvider | (private) |
| 353 | fn | deleteAccount | (private) |
| 374 | fn | handleEditGlmAccount | (private) |
| 382 | fn | syncCustomProvidersToConfig | (private) |
| 392 | struct | CustomProviderRow | (internal) |
| 493 | struct | MenuBarBadge | (internal) |
| 516 | class | TooltipWindow | (private) |
| 528 | method | init | (private) |
| 558 | fn | show | (internal) |
| 587 | fn | hide | (internal) |
| 593 | class | TooltipTrackingView | (private) |
| 595 | fn | updateTrackingAreas | (internal) |
| 606 | fn | mouseEntered | (internal) |
| 610 | fn | mouseExited | (internal) |
| 614 | fn | hitTest | (internal) |
| 620 | struct | NativeTooltipView | (private) |
| 622 | fn | makeNSView | (internal) |
| 628 | fn | updateNSView | (internal) |
| 634 | mod | extension View | (private) |
| 635 | fn | nativeTooltip | (internal) |
| 642 | struct | MenuBarHintView | (internal) |
| 657 | struct | OAuthSheet | (internal) |
| 783 | struct | OAuthStatusView | (private) |

## Quotio/Views/Screens/QuotaScreen.swift (1596 lines)

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
| 842 | struct | PlanBadgeV2Compact | (private) |
| 896 | struct | PlanBadgeV2 | (private) |
| 951 | struct | SubscriptionBadgeV2 | (private) |
| 992 | struct | AntigravityDisplayGroup | (private) |
| 1002 | struct | AntigravityGroupRow | (private) |
| 1079 | struct | AntigravityLowestBarLayout | (private) |
| 1098 | fn | displayPercent | (private) |
| 1160 | struct | AntigravityRingLayout | (private) |
| 1172 | fn | displayPercent | (private) |
| 1201 | struct | StandardLowestBarLayout | (private) |
| 1220 | fn | displayPercent | (private) |
| 1293 | struct | StandardRingLayout | (private) |
| 1305 | fn | displayPercent | (private) |
| 1340 | struct | AntigravityModelsDetailSheet | (private) |
| 1409 | struct | ModelDetailCard | (private) |
| 1476 | struct | UsageRowV2 | (private) |
| 1562 | struct | QuotaLoadingView | (private) |

## Quotio/Views/Screens/SettingsScreen.swift (2870 lines)

| Line | Kind | Name | Visibility |
| ---- | ---- | ---- | ---------- |
| 9 | struct | SettingsScreen | (internal) |
| 93 | struct | OperatingModeSection | (internal) |
| 158 | fn | handleModeSelection | (private) |
| 177 | fn | switchToMode | (private) |
| 192 | struct | RemoteServerSection | (internal) |
| 313 | fn | saveRemoteConfig | (private) |
| 321 | fn | reconnect | (private) |
| 336 | struct | UnifiedProxySettingsSection | (internal) |
| 556 | fn | loadConfig | (private) |
| 591 | fn | saveProxyURL | (private) |
| 604 | fn | saveRoutingStrategy | (private) |
| 613 | fn | saveSwitchProject | (private) |
| 622 | fn | saveSwitchPreviewModel | (private) |
| 631 | fn | saveRequestRetry | (private) |
| 640 | fn | saveMaxRetryInterval | (private) |
| 649 | fn | saveLoggingToFile | (private) |
| 658 | fn | saveRequestLog | (private) |
| 667 | fn | saveDebugMode | (private) |
| 680 | struct | LocalProxyServerSection | (internal) |
| 742 | struct | NetworkAccessSection | (internal) |
| 776 | struct | LocalPathsSection | (internal) |
| 800 | struct | PathLabel | (internal) |
| 824 | struct | NotificationSettingsSection | (internal) |
| 894 | struct | QuotaDisplaySettingsSection | (internal) |
| 936 | struct | RefreshCadenceSettingsSection | (internal) |
| 975 | struct | UpdateSettingsSection | (internal) |
| 1017 | struct | ProxyUpdateSettingsSection | (internal) |
| 1147 | fn | checkForUpdate | (private) |
| 1157 | fn | performUpgrade | (private) |
| 1176 | struct | ProxyVersionManagerSheet | (internal) |
| 1335 | fn | sectionHeader | (private) |
| 1350 | fn | isVersionInstalled | (private) |
| 1354 | fn | refreshInstalledVersions | (private) |
| 1358 | fn | loadReleases | (private) |
| 1372 | fn | installVersion | (private) |
| 1390 | fn | performInstall | (private) |
| 1411 | fn | activateVersion | (private) |
| 1429 | fn | deleteVersion | (private) |
| 1442 | struct | InstalledVersionRow | (private) |
| 1500 | struct | AvailableVersionRow | (private) |
| 1586 | fn | formatDate | (private) |
| 1604 | struct | MenuBarSettingsSection | (internal) |
| 1686 | struct | AppearanceSettingsSection | (internal) |
| 1715 | struct | PrivacySettingsSection | (internal) |
| 1737 | struct | GeneralSettingsTab | (internal) |
| 1776 | struct | AboutTab | (internal) |
| 1803 | struct | AboutScreen | (internal) |
| 2018 | struct | AboutUpdateSection | (internal) |
| 2074 | struct | AboutProxyUpdateSection | (internal) |
| 2210 | fn | checkForUpdate | (private) |
| 2220 | fn | performUpgrade | (private) |
| 2239 | struct | VersionBadge | (internal) |
| 2291 | struct | AboutUpdateCard | (internal) |
| 2382 | struct | AboutProxyUpdateCard | (internal) |
| 2539 | fn | checkForUpdate | (private) |
| 2549 | fn | performUpgrade | (private) |
| 2568 | struct | LinkCard | (internal) |
| 2655 | struct | ManagementKeyRow | (internal) |
| 2749 | struct | LaunchAtLoginToggle | (internal) |
| 2807 | struct | UsageDisplaySettingsSection | (internal) |

