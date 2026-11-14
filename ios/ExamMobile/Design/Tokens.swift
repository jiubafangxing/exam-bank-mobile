import SwiftUI

/// 与 shared/design/tokens.json 一一对应。
enum Tokens {
    // MARK: - 基础色
    static let primary = Color(hex: 0x1F5F99)
    static let primaryDeep = Color(hex: 0x103A5C)
    static let primaryDark = Color(hex: 0x16466F)
    static let primaryLight = Color(hex: 0x5AA7EA)
    static let primarySoft = Color(hex: 0xE8F1FA)
    static let background = Color(hex: 0xF4F6FB)
    static let surface = Color.white
    static let surfaceAlt = Color(hex: 0xEEF3F8)
    static let textPrimary = Color(hex: 0x1F2937)
    static let textSecondary = Color(hex: 0x8A94A6)
    static let textTertiary = Color(hex: 0x94A3B8)
    static let border = Color(hex: 0xE2EAF3)
    static let borderStrong = Color(hex: 0xCBD5E1)
    static let success = Color(hex: 0x15803D)
    static let successSoft = Color(hex: 0xECFDF5)
    static let warning = Color(hex: 0xB45309)
    static let warningSoft = Color(hex: 0xFFFBEB)
    static let danger = Color(hex: 0xC0392B)
    static let dangerSoft = Color(hex: 0xFDF2F2)
    static let info = Color(hex: 0x6D28D9)
    static let infoSoft = Color(hex: 0xF5F3FF)
    static let pink = Color(hex: 0xBE185D)
    static let pinkSoft = Color(hex: 0xFDF2F8)

    // MARK: - 扩展色板
    static let accent = Color(hex: 0x2FA6A0)
    static let accentSoft = Color(hex: 0xE6F7F5)
    static let coral = Color(hex: 0xE56B6F)
    static let coralSoft = Color(hex: 0xFDECEE)
    static let violet = Color(hex: 0x7C5CFC)
    static let violetSoft = Color(hex: 0xF0EDFF)
    static let amber = Color(hex: 0xF59E0B)
    static let amberSoft = Color(hex: 0xFFF5E5)
    static let sky = Color(hex: 0x0EA5E9)
    static let skySoft = Color(hex: 0xE6F6FE)
    static let slate = Color(hex: 0x64748B)
    static let slateSoft = Color(hex: 0xEEF2F7)
    static let rose = Color(hex: 0xEC4899)
    static let roseSoft = Color(hex: 0xFDECF4)
    static let heroEnd = Color(hex: 0x4F46E5)

    // MARK: - 几何
    static let pagePadding: CGFloat = 16
    static let cardRadius: CGFloat = 18
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24

    // MARK: - 渐变
    static let primaryGradient = LinearGradient(
        colors: [primaryDark, primary, Color(hex: 0x2F80C8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let heroGradient = LinearGradient(
        colors: [primary, heroEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let accentGradient = LinearGradient(
        colors: [primary, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let goldGradient = LinearGradient(
        colors: [warning, amber],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let successGradient = LinearGradient(
        colors: [success, Color(hex: 0x34D399)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let dangerGradient = LinearGradient(
        colors: [danger, coral],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - 阴影
    static let cardShadowColor = Color.black.opacity(0.05)
    static let cardShadowRadius: CGFloat = 10
    static let cardShadowY: CGFloat = 4
    static let heroShadowColor = primary.opacity(0.24)
    static let heroShadowRadius: CGFloat = 16
    static let heroShadowY: CGFloat = 10
    static let buttonShadowColor = primary.opacity(0.25)
    static let buttonShadowRadius: CGFloat = 10
    static let buttonShadowY: CGFloat = 6

    // MARK: - 图标色盘
    struct Palette {
        let color: Color
        let bg: Color
    }

    static let iconPalette: [Palette] = [
        Palette(color: primary, bg: primarySoft),
        Palette(color: accent, bg: accentSoft),
        Palette(color: coral, bg: coralSoft),
        Palette(color: violet, bg: violetSoft),
        Palette(color: amber, bg: amberSoft),
        Palette(color: sky, bg: skySoft),
        Palette(color: slate, bg: slateSoft),
        Palette(color: rose, bg: roseSoft)
    ]

    static func palette(_ index: Int) -> Palette {
        let count = iconPalette.count
        let safe = ((index % count) + count) % count
        return iconPalette[safe]
    }

    static func typeColor(_ type: String?) -> (fg: Color, bg: Color) {
        switch (type ?? "").uppercased() {
        case "MULTIPLE": return (Color(hex: 0x6D28D9), Color(hex: 0xF5F3FF))
        case "JUDGE": return (Color(hex: 0x15803D), Color(hex: 0xECFDF5))
        case "FILL": return (Color(hex: 0xB45309), Color(hex: 0xFFF7ED))
        case "ESSAY": return (Color(hex: 0xBE185D), Color(hex: 0xFDF2F8))
        default: return (Color(hex: 0x1F5F99), Color(hex: 0xEEF6FF))
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension View {
    func cardShadow() -> some View {
        shadow(
            color: Tokens.cardShadowColor,
            radius: Tokens.cardShadowRadius,
            x: 0,
            y: Tokens.cardShadowY
        )
    }

    func heroShadow() -> some View {
        shadow(
            color: Tokens.heroShadowColor,
            radius: Tokens.heroShadowRadius,
            x: 0,
            y: Tokens.heroShadowY
        )
    }
}
