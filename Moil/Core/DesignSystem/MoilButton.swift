import SwiftUI

/// 앱의 공통 버튼입니다. 수치는 피그마 로그인 버튼 기준입니다.
/// 배경과 여백을 라벨 안에 두어야 버튼 전체가 눌립니다.
/// 라벨 밖에 붙이면 글자 영역만 눌리기 때문입니다.
struct MoilButton: View {
    enum Style {
        case filled
        case outline

        var background: Color {
            switch self {
            case .filled: MoilColor.primary
            case .outline: .clear
            }
        }

        var foreground: Color {
            switch self {
            case .filled: .white
            case .outline: MoilColor.textPrimary
            }
        }
    }

    let title: String
    var style: Style = .filled
    var isEnabled = true
    /// 피그마: 로그인 버튼은 위 18 / 아래 17이라 높이 54가 됩니다.
    var height: CGFloat = 54
    var width: CGFloat?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MoilTypography.bold(16))
                .foregroundStyle(style.foreground)
                .frame(maxWidth: width == nil ? .infinity : nil)
                .frame(width: width, height: height)
                .background(style.background.opacity(isEnabled ? 1 : 0.78))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    if style == .outline {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(MoilColor.emptyStateBorder, lineWidth: 1)
                    }
                }
                // 배경 전체를 눌릴 수 있게 합니다.
                .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

extension MoilButton.Style: Equatable {}

#Preview("공통 버튼") {
    VStack(spacing: 14) {
        MoilButton(title: "로그인") {}
        MoilButton(title: "로그인", isEnabled: false) {}
        MoilButton(title: "새 그룹 만들기", style: .outline, height: 47, width: 215) {}
    }
    .padding(24)
    .background(MoilColor.background)
}
