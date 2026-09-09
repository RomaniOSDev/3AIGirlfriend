import SwiftUI

enum AppColors {
    static let white = Color.white
    static let primary = Color(hex: 0x02AFEF)
    static let primaryDark = Color(hex: 0x018CD0)
    static let bubbleAI = Color(hex: 0xE8F7FE)
    static let planSelectedFill = Color(hex: 0xE8F7FE)
    static let textPrimary = Color(hex: 0x111827)
    static let textSecondary = Color(hex: 0x6B7280)
    static let textTertiary = Color(hex: 0x9CA3AF)
    static let danger = Color(hex: 0xEF4444)
    static let border = Color(hex: 0xE5E7EB)
    static let background = Color.white
    static let softGray = Color(hex: 0xF3F4F6)
    static let online = Color(hex: 0x22C55E)
    static let star = Color(hex: 0xFBBF24)

    static let primaryGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .leading,
        endPoint: .trailing
    )
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
