import SwiftUI

/// 与 shared/design/tokens.json 一一对应。
enum Tokens {
    static let primary = Color(hex: 0x1F5F99)
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

    static let pagePadding: CGFloat = 16
    static let cardRadius: CGFloat = 16
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24

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
