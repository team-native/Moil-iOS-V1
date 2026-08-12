import SwiftUI

enum MoilColor {
    // Brand
    static let primary = Color("BrandPrimary")
    static let primaryPressed = Color("BrandPrimaryPressed")
    static let error = Color("Error")
    static let success = Color("Success")

    // Neutral
    static let background = Color("Background")
    static let systemBackground = Color("MoilSystemBackground")
    static let surface = Color("Surface")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")
    static let fieldPlaceholder = Color("FieldPlaceholder")
    static let emptyStateBorder = Color("EmptyStateBorder")
    static let toggleOff = Color("ToggleOff")
    static let label = Color("MoilLabel")
    static let launchBackground = Color("LaunchBackground")
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

/// 피그마 원본 서체인 Inter를 씁니다.
/// Inter에는 한글 글자가 없어서, 같은 굵기의 Pretendard를 뒤에 이어 붙여
/// 영문·숫자는 Inter로, 한글은 Pretendard로 그려지게 합니다.
/// (Pretendard의 영문 자형은 Inter를 바탕으로 만들어져 두 서체가 섞여도 어긋나 보이지 않습니다.)
enum MoilTypography {
    static func regular(_ size: CGFloat) -> Font {
        font("Inter-Regular", fallback: "Pretendard-Regular", size: size)
    }

    static func semibold(_ size: CGFloat) -> Font {
        font("Inter-SemiBold", fallback: "Pretendard-SemiBold", size: size)
    }

    static func bold(_ size: CGFloat) -> Font {
        font("Inter-Bold", fallback: "Pretendard-Bold", size: size)
    }

    /// Bold보다 굵어야 하는 큰 제목에 씁니다.
    static func heavy(_ size: CGFloat) -> Font {
        font("Inter-ExtraBold", fallback: "Pretendard-Bold", size: size)
    }

    private static func font(_ name: String, fallback: String, size: CGFloat) -> Font {
        let descriptor = UIFontDescriptor(fontAttributes: [
            .name: name,
            .cascadeList: [UIFontDescriptor(fontAttributes: [.name: fallback])]
        ])
        return Font(UIFont(descriptor: descriptor, size: size))
    }
}

/// 앱의 모든 입력 칸이 같은 여백과 모서리를 쓰도록 맞춰 주는 스타일입니다.
struct MoilFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(MoilTypography.regular(15))
            .padding(.horizontal, 16)
            // 높이를 고정하지 않으면 커서가 생길 때 내용 높이가 달라져 칸이 미세하게 흔들립니다.
            .frame(minHeight: 53)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MoilColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

extension View {
    func moilField() -> some View {
        modifier(MoilFieldStyle())
    }
}
