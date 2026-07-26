import SwiftUI

struct EmptyCalendarView: View {
    var onJoin: () -> Void = { }
    var onCreate: () -> Void = { }
    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 150)
            Image("MoilMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 128)
            Text("아직 속한 그룹이 없어요")
                .font(MoilTypography.bold(19))
                .foregroundStyle(MoilColor.groupDetailTextPrimary)
                .padding(.top, 22)
            Text("초대 코드로 그룹에 참여하거나\n새 그룹을 만들어보세요")
                .font(MoilTypography.regular(14))
                .foregroundStyle(MoilColor.groupDetailTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 8)
            Button("그룹 참여하기", action: onJoin)
                .font(MoilTypography.bold(16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(MoilColor.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.top, 32)
            Button("새 그룹 만들기", action: onCreate)
                .font(MoilTypography.bold(16))
                .foregroundStyle(MoilColor.groupDetailTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .overlay { RoundedRectangle(cornerRadius: 14).stroke(MoilColor.groupDetailSeparator, lineWidth: 1) }
                .padding(.top, 12)
            Spacer()
        }
        .padding(.horizontal, 32)
        .background(MoilColor.groupDetailBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MoilTabBar(selected: .calendar, style: .dark) { tab in
                if tab == .members { onJoin() }
                if tab == .create { onCreate() }
            }
        }
    }
}

#Preview("빈 캘린더") {
    EmptyCalendarView()
}
