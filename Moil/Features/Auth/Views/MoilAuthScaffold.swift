import SwiftUI

/// auth 화면들이 제목, 본문, 하단 영역을 같은 위치에서 시작하도록 맞춰 주는 공통 레이아웃입니다.
/// 수치는 피그마 auth 화면 기준입니다.
struct MoilAuthScaffold<Content: View, Bottom: View>: View {
    let title: String
    var subtitle: String?
    var onBack: (() -> Void)?
    @ViewBuilder let content: Content
    @ViewBuilder let bottom: Bottom

    /// 피그마: 좌우 24, 제목 상단 76(안전 영역 62 + 14)
    private let horizontalPadding: CGFloat = 24
    private let titleTopPadding: CGFloat = 14

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                if let onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(MoilColor.textPrimary)
                            .frame(width: 9, height: 16)
                    }
                }
                // 피그마: Bold 26
                Text(title)
                    .font(MoilTypography.bold(26))
                    .foregroundStyle(MoilColor.textPrimary)
            }
            .frame(height: 41)
            .safeAreaPadding(.top, titleTopPadding)

            if let subtitle {
                // 피그마: Regular 13, 줄 높이 19.5
                Text(subtitle)
                    .font(MoilTypography.regular(13))
                    .foregroundStyle(MoilColor.textSecondary)
                    .lineSpacing(19.5 - 13)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }

            content

            Spacer(minLength: 24)

            bottom
                .safeAreaPadding(.bottom, 30)
        }
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: 402, maxHeight: .infinity, alignment: .topLeading)
        .background(MoilColor.background.ignoresSafeArea())
    }
}

/// auth 화면 하단의 기본 버튼입니다. 피그마: 위 18 / 아래 17, 모서리 14, Bold 16
struct MoilAuthButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        MoilButton(title: title, isEnabled: isEnabled, action: action)
    }
}
