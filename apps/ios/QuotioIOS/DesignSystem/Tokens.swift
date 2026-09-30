import SwiftUI
import QuotioMobile

/// Design tokens. Feature views use these instead of literal sizes, fonts and colors.
/// Spacing follows a 4 pt grid. See DESIGN_SYSTEM.md.
enum DS {
    enum Space {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }

    enum Radius {
        static let card: CGFloat = 16
        static let tile: CGFloat = 10
    }

    enum Size {
        static let hairline: CGFloat = 0.5
        static let bar: CGFloat = 4
        static let providerIcon: CGFloat = 16
        static let sectionIcon: CGFloat = 14
        static let statusDot: CGFloat = 8
        static let chart: CGFloat = 120
        /// Tile labels longer than this span both grid columns.
        static let longLabel = 18
    }

    enum Palette {
        static let background = Color(.systemGroupedBackground)
        static let surface = Color(.secondarySystemGroupedBackground)
        static let tile = Color(.tertiarySystemGroupedBackground)
        static let hairline = Color(.separator)
        static let track = Color(.systemFill)
        static let accent = Color.green
        static let healthy = Color.green
        static let low = Color.orange
        static let critical = Color.red
        /// Stale data and windows without a value.
        static let muted = Color.secondary

        static func level(_ level: QuotaLevel) -> Color {
            switch level {
            case .healthy: healthy
            case .low: low
            case .critical: critical
            case .unknown: muted
            }
        }
    }

    enum Typography {
        static let sectionTitle = Font.footnote.weight(.semibold)
        static let accountTitle = Font.subheadline.weight(.medium)
        static let groupTitle = Font.caption.weight(.semibold)
        static let tileLabel = Font.caption
        static let percent = Font.headline.monospacedDigit()
        static let countdown = Font.caption2.monospacedDigit()
        static let valueLabel = Font.footnote
        static let value = Font.footnote.monospacedDigit().weight(.medium)
        static let badge = Font.caption2.weight(.semibold)
        static let caption = Font.caption2
        static let chip = Font.footnote.weight(.medium)
        static let detailPercent = Font.title3.monospacedDigit().weight(.semibold)
        static let bannerTitle = Font.footnote.weight(.semibold)
        static let detailTitle = Font.headline
        static let emphasis = Font.title2.weight(.semibold)
        static let lockScreen = Font.title
    }

    enum Motion {
        static let standard = Animation.smooth(duration: 0.25)
        static func standard(reduceMotion: Bool) -> Animation? { reduceMotion ? nil : standard }
    }

    /// Spacing that changes with the Compact/Comfortable display setting.
    struct Layout {
        let cardPadding: CGFloat
        let cardSpacing: CGFloat
        let tilePadding: CGFloat
        let gridSpacing: CGFloat
        let sectionSpacing: CGFloat

        static func of(_ density: Density) -> Layout {
            switch density {
            case .comfortable: Layout(cardPadding: Space.m, cardSpacing: Space.s, tilePadding: Space.s, gridSpacing: Space.s, sectionSpacing: Space.l)
            case .compact: Layout(cardPadding: Space.s + Space.xxs, cardSpacing: Space.s - Space.xxs, tilePadding: Space.s - Space.xxs, gridSpacing: Space.s - Space.xxs, sectionSpacing: Space.m)
            }
        }
    }
}

extension EnvironmentValues {
    @Entry var density: Density = .comfortable
}

extension View {
    /// Flat content surface with a hairline border.
    func cardSurface() -> some View {
        background(DS.Palette.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .strokeBorder(DS.Palette.hairline, lineWidth: DS.Size.hairline)
            }
    }

    func tileSurface() -> some View {
        background(DS.Palette.tile, in: RoundedRectangle(cornerRadius: DS.Radius.tile, style: .continuous))
    }
}
