import SwiftUI

struct CreateGroupView: View {
    @State private var name = ""
    @State private var selectedColor: Color = .teal
    private let colors: [Color] = [.teal, .purple, .pink]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) { Image(systemName: "chevron.left"); Text("새 그룹 만들기").font(MoilTypography.bold(22)) }.padding(.top, 24)
            Text("그룹 이름").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 26).padding(.bottom, 10)
            TextField("예: 우리 가족", text: $name).font(MoilTypography.regular(15)).padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
            Text("내 프로필 색 선택").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 18).padding(.bottom, 10)
            HStack(spacing: 12) { ForEach(colors, id: \.self) { color in Button { selectedColor = color } label: { Circle().fill(color).frame(width: 46, height: 46).overlay { Circle().stroke(MoilColor.primary, lineWidth: selectedColor == color ? 3 : 0).padding(-5) } } } }
            Spacer()
            Button("그룹 만들기") { }.font(MoilTypography.bold(16)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 54).background(name.isEmpty ? MoilColor.primary.opacity(0.78) : MoilColor.primary).clipShape(RoundedRectangle(cornerRadius: 14)).padding(.bottom, 30)
        }.padding(.horizontal, 24).background(MoilColor.background.ignoresSafeArea())
    }
}
