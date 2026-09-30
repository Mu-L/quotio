# Quotio iOS design system

An instrument panel: every element is data or structure. The macOS menu bar is the
reference for information density and hierarchy.

## Rules

- Components live in `QuotioIOS/DesignSystem/`. Feature views use `DS` tokens from `Tokens.swift`. No literal sizes, fonts or colors.
- Flat content surfaces (`cardSurface()`, `tileSurface()`) with a 0.5 pt hairline.
  Liquid Glass is only for navigation chrome: tab bar, toolbar items, filter chips.
- Numbers use monospaced digits so values don't jitter on refresh.
- Color carries meaning only: green > 50 %, amber 20–50 %, red < 20 %, gray for stale
  data or windows without a value. Plan badges stay neutral.
- Layouts reflow at accessibility sizes: tile grids go to one column and rows stack.
- Copy lives in `Shared/Localizable.xcstrings` (en, vi, fr, zh-Hans).

## Tokens

| Group | Values |
| --- | --- |
| `Space` | 2, 4, 8, 12, 16, 20, 24 (4 pt grid) |
| `Radius` | card 16, tile 10 |
| `Size` | hairline 0.5, bar 4, provider icon 16, section icon 14, status dot 8 |
| `Typography` | percent = headline, tile label = caption, value = footnote, caption = caption2 |
| `Layout.of(density)` | comfortable or compact padding and spacing |
| `Motion.standard` | 0.25 s smooth; `nil` with Reduce Motion |

## Components

| Component | Purpose |
| --- | --- |
| `ProviderIcon` | Monochrome provider mark, same mapping as the menu bar |
| `QuotaBar` | 4 pt bar; an empty critical bar tints its track red |
| `QuotaTile` | Window label, reset countdown, colored percent, bar |
| `PlanBadge` | Neutral pill for plan or tier |
| `ValueRow` | Label and right-aligned value (credits, statuses) |
| `FreshnessLabel` | Relative age; amber with a clock icon when data is old |
| `AccountCard` | Header, grouped tiles, value rows |
| `EmptyAccountRow` | One muted line for an account without quota data |
| `ProviderSectionHeader` | Provider icon and name above its accounts |
| `ProviderFilterBar` | All plus one chip per provider present |
| `ConnectionChip` | Status dot and Mac name in the top bar |
| `ConnectionBanner` | The single row shown when the Mac can't be read |

## Data rules

Presentation rules live in `Sources/QuotioMobile` so the app and widgets share them and they
are unit tested:

- `QuotaFormat`: percent rule (truncate remaining, used = 100 − remaining; matches the
  macOS `QuotaDisplayMode.displayValue`), countdowns, amounts and currency.
- `DisplayNames`: provider labels (`gemini-weekly` → "Gemini · Weekly"), plans,
  statuses, issue codes and reset descriptions. Unknown values are prettified.
- `AccountPresentation`: tiles vs value rows, groups, empty reasons, provider sections.
- `ConnectionIssue`: one typed connection problem with title, detail and steps.

## Previews

Each component has a "States" preview and a "Variants" preview built with
`PreviewMatrix` (EN light, VI dark, zh-Hans light, EN dark at AX5). Data comes from
`PreviewFixtures`. `PreviewMatrix` switches the SwiftUI locale, so view-level copy and
numbers localize; strings produced in `QuotioMobile` follow the process language. Set
the canvas language in Xcode's preview settings to check those.
