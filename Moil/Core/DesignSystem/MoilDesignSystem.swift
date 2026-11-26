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
/// 라이트모드는 흰 칸에 옅은 그림자로, 다크모드는 한 단계 밝은 칸과 얇은 외곽선으로 배경과 구분합니다.
struct MoilFieldStyle: ViewModifier {
    var background: Color = MoilColor.fieldBackground

    func body(content: Content) -> some View {
        content
            .font(MoilTypography.regular(15))
            .padding(.horizontal, 16)
            // 높이를 고정하지 않으면 커서가 생길 때 내용 높이가 달라져 칸이 미세하게 흔들립니다.
            .frame(minHeight: 53)
            .frame(maxWidth: .infinity, alignment: .leading)
            .moilFieldSurface(background: background)
    }
}

/// 입력칸 모양(배경·모서리·라이트 그림자·다크 외곽선)만 입힙니다. 인증번호 칸처럼 크기를 따로 정하는 칸에도 씁니다.
struct MoilFieldSurface: ViewModifier {
    var background: Color = MoilColor.fieldBackground
    var cornerRadius: CGFloat = 14
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            // 그림자는 배경 모양에만 줍니다. 내용 전체에 주면 글자·아이콘에도 번짐이 생깁니다.
            .background {
                shape
                    .fill(background)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.07), radius: 12, x: 0, y: 4)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.04), radius: 2, x: 0, y: 1)
            }
            .overlay {
                if colorScheme == .dark {
                    shape.strokeBorder(MoilColor.textPrimary.opacity(0.12), lineWidth: 1)
                }
            }
    }
}

/// 누르는 동안 살짝 줄어들고 흐려지는 버튼 스타일입니다. 손을 떼면 부드럽게 돌아옵니다.
struct MoilPressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

/// 앱 전체에서 같은 느낌으로 쓰는 애니메이션입니다. 튀지 않게 감속하는 스프링을 씁니다.
enum MoilMotion {
    /// 화면 요소가 나타나고 사라질 때
    static let standard = Animation.smooth(duration: 0.32)
    /// 눌림·선택처럼 바로 반응해야 할 때
    static let quick = Animation.snappy(duration: 0.22)
    /// 화면·단계 전환
    static let page = Animation.smooth(duration: 0.38)
}

extension View {
    func moilField(background: Color = MoilColor.fieldBackground) -> some View {
        modifier(MoilFieldStyle(background: background))
    }

    func moilFieldSurface(background: Color = MoilColor.fieldBackground, cornerRadius: CGFloat = 14) -> some View {
        modifier(MoilFieldSurface(background: background, cornerRadius: cornerRadius))
    }

    /// 입력 중 빈 곳을 누르면 키보드를 내립니다. 버튼·입력 칸의 탭은 가로채지 않도록 화면 배경 뷰에 붙여 씁니다.
    func moilDismissKeyboardOnTap() -> some View {
        contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

/// 흰색 마스코트입니다. 라이트모드의 흰 배경에서는 윤곽이 사라져, 옅은 그림자로 형태가 보이게 합니다.
struct MoilMascotImage: View {
    var width: CGFloat
    var height: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Image("MoilMascot")
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.14), radius: 6, x: 0, y: 2)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 1, x: 0, y: 0)
    }
}
