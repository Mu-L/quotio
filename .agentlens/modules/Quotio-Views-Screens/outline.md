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

## Quotio/Views/Screens/SettingsScreen.swift (2857 lines)

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
| 547 | fn | loadConfig | (private) |
| 578 | fn | saveProxyURL | (private) |
| 591 | fn | saveRoutingStrategy | (private) |
| 600 | fn | saveSwitchProject | (private) |
| 609 | fn | saveSwitchPreviewModel | (private) |
| 618 | fn | saveRequestRetry | (private) |
| 627 | fn | saveMaxRetryInterval | (private) |
| 636 | fn | saveLoggingToFile | (private) |
| 645 | fn | saveRequestLog | (private) |
| 654 | fn | saveDebugMode | (private) |
| 667 | struct | LocalProxyServerSection | (internal) |
| 729 | struct | NetworkAccessSection | (internal) |
| 763 | struct | LocalPathsSection | (internal) |
| 787 | struct | PathLabel | (internal) |
| 811 | struct | NotificationSettingsSection | (internal) |
| 881 | struct | QuotaDisplaySettingsSection | (internal) |
| 923 | struct | RefreshCadenceSettingsSection | (internal) |
| 962 | struct | UpdateSettingsSection | (internal) |
| 1004 | struct | ProxyUpdateSettingsSection | (internal) |
| 1134 | fn | checkForUpdate | (private) |
| 1144 | fn | performUpgrade | (private) |
| 1163 | struct | ProxyVersionManagerSheet | (internal) |
| 1322 | fn | sectionHeader | (private) |
| 1337 | fn | isVersionInstalled | (private) |
| 1341 | fn | refreshInstalledVersions | (private) |
| 1345 | fn | loadReleases | (private) |
| 1359 | fn | installVersion | (private) |
| 1377 | fn | performInstall | (private) |
| 1398 | fn | activateVersion | (private) |
| 1416 | fn | deleteVersion | (private) |
| 1429 | struct | InstalledVersionRow | (private) |
| 1487 | struct | AvailableVersionRow | (private) |
| 1573 | fn | formatDate | (private) |
| 1591 | struct | MenuBarSettingsSection | (internal) |
| 1673 | struct | AppearanceSettingsSection | (internal) |
| 1702 | struct | PrivacySettingsSection | (internal) |
| 1724 | struct | GeneralSettingsTab | (internal) |
| 1763 | struct | AboutTab | (internal) |
| 1790 | struct | AboutScreen | (internal) |
| 2005 | struct | AboutUpdateSection | (internal) |
| 2061 | struct | AboutProxyUpdateSection | (internal) |
| 2197 | fn | checkForUpdate | (private) |
| 2207 | fn | performUpgrade | (private) |
| 2226 | struct | VersionBadge | (internal) |
| 2278 | struct | AboutUpdateCard | (internal) |
| 2369 | struct | AboutProxyUpdateCard | (internal) |
| 2526 | fn | checkForUpdate | (private) |
| 2536 | fn | performUpgrade | (private) |
| 2555 | struct | LinkCard | (internal) |
| 2642 | struct | ManagementKeyRow | (internal) |
| 2736 | struct | LaunchAtLoginToggle | (internal) |
| 2794 | struct | UsageDisplaySettingsSection | (internal) |

