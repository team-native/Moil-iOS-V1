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
    /// 팝업(시트) 안 입력칸 배경입니다. 다크모드에서는 팝업 배경(surface)이 검정이라
    /// 입력칸이 묻히지 않도록 한 단계 밝은 회색을 씁니다. 라이트모드는 surface와 같습니다.
    static let popupField = Color("PopupField")
    static let fieldBackground = Color("FieldBackground")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")
    static let label = Color("MoilLabel")
    static let launchBackground = Color("LaunchBackground")
    static let groupDetailBackground = Color("GroupDetailBackground")
    static let groupDetailSurface = Color("GroupDetailSurface")
    static let groupDetailTextPrimary = Color("GroupDetailTextPrimary")
    static let groupDetailTextSecondary = Color("GroupDetailTextSecondary")
    static let groupDetailSeparator = Color("GroupDetailSeparator")
    /// 캘린더의 일요일·공휴일 날짜 숫자 색입니다. 따로 에셋을 두지 않고 에러 빨강을 같이 씁니다.
    static let holiday = Color("Error")
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

/// 앱의 모든 입력 칸이 같은 여백과 모서리를 쓰도록 맞춰 주는 스타일입니다.
struct MoilFieldStyle: ViewModifier {
    var background: Color = MoilColor.fieldBackground

    func body(content: Content) -> some View {
        content
            .font(MoilTypography.regular(15))
            .padding(.horizontal, 16)
            // 높이를 고정하지 않으면 커서가 생길 때 내용 높이가 달라져 칸이 미세하게 흔들립니다.
            .frame(minHeight: 53)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

extension View {
    func moilField(background: Color = MoilColor.fieldBackground) -> some View {
        modifier(MoilFieldStyle(background: background))
    }

    /// 입력 중 빈 곳을 누르면 키보드를 내립니다. 버튼·입력 칸의 탭은 가로채지 않도록 화면 배경 뷰에 붙여 씁니다.
    func moilDismissKeyboardOnTap() -> some View {
        contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}
