import SwiftUI

enum MoilColor {
    // Brand
    static let primary = Color("BrandPrimary")
    static let primaryPressed = Color("BrandPrimaryPressed")
    static let error = Color("Error")

    // Neutral
    static let background = Color("Background")
    static let systemBackground = Color("MoilSystemBackground")
    static let surface = Color.white
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")
    static let label = Color("MoilLabel")
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
