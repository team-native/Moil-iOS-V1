import SwiftUI

struct EmptyCalendarView: View {
    var onJoin: () -> Void = { }
    var onCreate: () -> Void = { }
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            Image("MoilMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 98)
            Text("아직 속한 그룹이 없어요")
                .font(MoilTypography.bold(19))
                .foregroundStyle(MoilColor.textPrimary)
                .padding(.top, 16)
            Text("초대 코드로 그룹에 참여하거나\n새 그룹을 만들어보세요")
                .font(MoilTypography.regular(14))
                .foregroundStyle(MoilColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 6)
            Button("그룹 참여하기", action: onJoin)
                .font(MoilTypography.bold(16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(MoilColor.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.top, 24)
            Button("새 그룹 만들기", action: onCreate)
                .font(MoilTypography.bold(16))
                .foregroundStyle(MoilColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .overlay { RoundedRectangle(cornerRadius: 14).stroke(MoilColor.textTertiary.opacity(0.35), lineWidth: 1) }
                .padding(.top, 10)
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 32)
        .background(MoilColor.background.ignoresSafeArea())
    }
}

#Preview("빈 캘린더") {
    EmptyCalendarView()
}
