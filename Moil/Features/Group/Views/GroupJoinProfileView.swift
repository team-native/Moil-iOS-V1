import SwiftUI

struct GroupJoinProfileView: View {
    @State private var nickname = ""
    @State private var selectedColor: Color = .teal
    private let colors: [Color] = [.teal, .purple, .pink]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("프로필 설정").font(MoilTypography.bold(26)).padding(.top, 34)
            HStack(spacing: 10) { AvatarStack(); VStack(alignment: .leading, spacing: 4) { Text("우리 가족").font(MoilTypography.bold(14)); Text("구성원 4명").font(MoilTypography.regular(11)).foregroundStyle(MoilColor.textSecondary) } }
                .padding(13).background(.white).clipShape(RoundedRectangle(cornerRadius: 14)).padding(.top, 22)
            Text("이 그룹에서 사용할 이름").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 18).padding(.bottom, 10)
            TextField("닉네임 입력", text: $nickname).font(MoilTypography.regular(15)).padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 12))
            Text("이미 사용 중인 프로필").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 16).padding(.bottom, 10)
            HStack(spacing: 14) { ForEach([Color.blue, .red, .green, .orange], id: \.self) { color in Circle().fill(color).frame(width: 34, height: 34).opacity(0.35) } }
            Text("내 프로필 색 선택").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 18).padding(.bottom, 10)
            HStack(spacing: 12) { ForEach(colors, id: \.self) { color in Button { selectedColor = color } label: { Circle().fill(color).frame(width: 36, height: 36).overlay { Circle().stroke(MoilColor.primary, lineWidth: selectedColor == color ? 3 : 0).padding(-5) } } } }
            Spacer()
            Button("참여하기") { }.font(MoilTypography.bold(16)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 54).background(MoilColor.primary).clipShape(RoundedRectangle(cornerRadius: 14)).padding(.bottom, 30)
        }.padding(.horizontal, 24).background(MoilColor.background.ignoresSafeArea())
    }
}
private struct AvatarStack: View { var body: some View { HStack(spacing: -8) { ForEach([Color.blue, .red, .green, .orange], id: \.self) { Circle().fill($0).frame(width: 22, height: 22).overlay { Image(systemName: "person.fill").font(.system(size: 8)).foregroundStyle(.white) } } } } }
