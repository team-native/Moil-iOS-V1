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
                    .font(MoilTypography.heavy(30))
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

/// 내비게이션 바가 없는 화면에서 iOS 기본 형태를 흉내 내는 상단 바입니다.
/// 뒤로 가기 버튼은 왼쪽, 제목은 가운데에 둡니다.
struct MoilInlineHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(MoilTypography.bold(17))
                .foregroundStyle(MoilColor.textPrimary)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(MoilColor.textPrimary)
                        .frame(width: 44, height: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
        .safeAreaPadding(.top, 8)
    }
}
