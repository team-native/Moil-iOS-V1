import SwiftUI

struct EmptyCalendarView: View {
    var onJoin: () -> Void = { }
    var onCreate: () -> Void = { }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("캘린더").font(MoilTypography.bold(26))
                Spacer()
            }
            .padding(.top, 24)
            Spacer()
            Image(systemName: "person.3.sequence.fill").font(.system(size: 64)).foregroundStyle(MoilColor.primary.opacity(0.55))
                .frame(width: 112, height: 112).background(.white, in: Circle())
            Text("아직 속한 그룹이 없어요").font(MoilTypography.bold(20)).padding(.top, 24)
            Text("초대 코드로 그룹에 참여하거나\n새 그룹을 만들어보세요").font(MoilTypography.regular(14)).foregroundStyle(MoilColor.textSecondary).multilineTextAlignment(.center).lineSpacing(5).padding(.top, 10)
            Button("그룹 참여하기", action: onJoin).font(MoilTypography.bold(16)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 54).background(MoilColor.primary).clipShape(RoundedRectangle(cornerRadius: 14)).padding(.top, 32)
            Button("새 그룹 만들기", action: onCreate).font(MoilTypography.bold(16)).foregroundStyle(MoilColor.textPrimary).frame(maxWidth: .infinity).frame(height: 54).overlay { RoundedRectangle(cornerRadius: 14).stroke(Color("TextTertiary").opacity(0.3), lineWidth: 1) }.padding(.top, 12)
            Spacer()
        }.padding(.horizontal, 24).background(MoilColor.background.ignoresSafeArea())
    }
}
