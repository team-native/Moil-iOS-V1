import SwiftUI

enum MoilColor {
    // Brand
    static let primary = Color(hex: 0xBF6B60)
    static let primaryPressed = Color(hex: 0xA9564C)
    static let error = Color(hex: 0xCF4040)

    // Neutral
    static let background = Color(hex: 0xF6F5F2)
    static let systemBackground = Color(hex: 0xF2F2F7)
    static let surface = Color.white
    static let textPrimary = Color(hex: 0x15110D)
    static let textSecondary = Color(hex: 0x5D5751)
    static let textTertiary = Color(hex: 0x97918C)
    static let label = Color(hex: 0x5A5450)
    static let black = Color.black
    static let black25 = Color.black.opacity(0.25)
    static let black35 = Color.black.opacity(0.35)
    static let black40 = Color.black.opacity(0.40)
}

enum MoilTypography {
    static func regular(_ size: CGFloat) -> Font {
        .custom("Pretendard-Regular", size: size)
    }

    static func semibold(_ size: CGFloat) -> Font {
        .custom("Pretendard-SemiBold", size: size)
    }

    static func bold(_ size: CGFloat) -> Font {
        .custom("Pretendard-Bold", size: size)
    }
}

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
