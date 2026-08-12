import SwiftUI

/// 그룹이 하나도 없을 때 캘린더와 멤버 탭에 표시합니다. 수치는 피그마 `캘린더 (그룹 없음)` 기준입니다.
struct EmptyCalendarView: View {
    var onJoin: () -> Void = { }
    var onCreate: () -> Void = { }

    /// 피그마: 버튼 좌우 여백 93/94 → 폭 215, 높이 47
    private let buttonWidth: CGFloat = 215
    private let buttonHeight: CGFloat = 47

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            // 피그마: 82x82
            Image("EmptyGroupMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)

            // 피그마: Bold 19, 위 17
            Text("아직 속한 그룹이 없어요")
                .font(MoilTypography.bold(19))
                .foregroundStyle(MoilColor.textPrimary)
                .padding(.top, 17)

            // 피그마: Regular 14, 줄 높이 21, 위 7
            Text("초대 코드로 그룹에 참여하거나\n새 그룹을 만들어보세요")
                .font(MoilTypography.regular(14))
                .foregroundStyle(MoilColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(21 - 14)
                .padding(.top, 7)

            // 피그마: 설명 아래 32
            MoilButton(title: "그룹 참여하기", height: buttonHeight, width: buttonWidth, action: onJoin)
                .padding(.top, 32)

            // 피그마: 버튼 사이 14, 테두리 #383531
            MoilButton(title: "새 그룹 만들기", style: .outline, height: buttonHeight, width: buttonWidth, action: onCreate)
                .padding(.top, 14)

            Spacer(minLength: 0)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MoilColor.background.ignoresSafeArea())
    }
}

#Preview("빈 캘린더") {
    EmptyCalendarView()
}
