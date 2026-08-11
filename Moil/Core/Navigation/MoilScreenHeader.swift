import SwiftUI

/// 캘린더를 제외한 화면들이 같은 크기와 위치에서 제목을 시작하도록 맞춰 주는 공통 헤더입니다.
struct MoilScreenHeader: View {
    let title: String
    var subtitle: String?
    var onBack: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                if let onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(MoilColor.textPrimary)
                            .frame(width: 32, height: 32, alignment: .leading)
                    }
                }
                Text(title)
                    .font(MoilTypography.bold(30))
                    .foregroundStyle(MoilColor.textPrimary)
                Spacer(minLength: 0)
            }
            if let subtitle {
                Text(subtitle)
                    .font(MoilTypography.regular(13))
                    .foregroundStyle(MoilColor.textSecondary)
                    .padding(.top, 6)
            }
        }
        .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
        .padding(.top, MoilTabScreenMetrics.titleTopPadding)
        .padding(.bottom, MoilTabScreenMetrics.titleBottomPadding)
    }
}

#Preview("공통 화면 제목") {
    VStack(spacing: 0) {
        MoilScreenHeader(title: "마이페이지")
        MoilScreenHeader(title: "멤버", subtitle: "우리 가족")
        MoilScreenHeader(title: "비밀번호 변경", onBack: {})
        Spacer()
    }
    .background(MoilColor.background)
}
