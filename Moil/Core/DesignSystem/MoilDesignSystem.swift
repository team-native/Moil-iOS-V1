import SwiftUI

enum MoilColor {
    // Brand
    static let primary = Color("BrandPrimary")
    static let primaryPressed = Color("BrandPrimaryPressed")
    static let error = Color("Error")

    // Neutral
    static let background = Color("Background")
    static let systemBackground = Color("MoilSystemBackground")
    static let surface = Color("Surface")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")
    static let label = Color("MoilLabel")
    static let groupDetailBackground = Color("GroupDetailBackground")
    static let groupDetailSurface = Color("GroupDetailSurface")
    static let groupDetailTextPrimary = Color("GroupDetailTextPrimary")
    static let groupDetailTextSecondary = Color("GroupDetailTextSecondary")
    static let groupDetailSeparator = Color("GroupDetailSeparator")
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

    /// 번들에는 Bold가 가장 굵어, 그보다 굵게 보여야 하는 큰 제목에만 굵기를 더 올려 씁니다.
    static func heavy(_ size: CGFloat) -> Font {
        .custom("Pretendard-Bold", size: size).weight(.black)
    }
}
