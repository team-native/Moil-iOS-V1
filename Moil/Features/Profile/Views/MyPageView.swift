import SwiftUI

struct MyPageView: View {
    @State private var isDarkMode = false
    @State private var isGroupDetailPresented = false
    let onCreateGroup: () -> Void

    init(onCreateGroup: @escaping () -> Void = {}) {
        self.onCreateGroup = onCreateGroup
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Circle().fill(.green).frame(width: 56, height: 56).overlay { Image(systemName: "person.fill").foregroundStyle(.white) }
                    Text("나").font(MoilTypography.bold(21))
                }
                GroupSection(title: "내 그룹") {
                    Button { isGroupDetailPresented = true } label: { GroupRow("우리 가족", .blue) }
                    Divider(); Button { isGroupDetailPresented = true } label: { GroupRow("대학 동기", .green) }
                    Divider(); Button { isGroupDetailPresented = true } label: { GroupRow("회사 팀", .green) }
                    Divider()
                    Button(action: onCreateGroup) { Text("+ 새 그룹 만들기").font(MoilTypography.semibold(15)).foregroundStyle(MoilColor.primary).padding(14) }
                }
                GroupSection(title: "환경설정") {
                    Toggle("다크 모드", isOn: $isDarkMode).padding(14).tint(MoilColor.primary)
                }
                Button("로그아웃") { }
                    .font(MoilTypography.semibold(15)).foregroundStyle(MoilColor.error)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(16).padding(.top, 28)
        }
        .background(MoilColor.background)
        .sheet(isPresented: $isGroupDetailPresented) { GroupDetailView() }
    }
}

private struct GroupSection<Content: View>: View {
    let title: String; @ViewBuilder let content: Content
    var body: some View { VStack(alignment: .leading, spacing: 8) { Text(title).font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary); VStack(spacing: 0) { content }.background(.white).clipShape(RoundedRectangle(cornerRadius: 18)) } }
}
private struct GroupRow: View {
    let title: String; let color: Color
    init(_ title: String, _ color: Color) { self.title = title; self.color = color }
    var body: some View { HStack { Circle().fill(color).frame(width: 8, height: 8); Text(title).font(MoilTypography.semibold(15)); Spacer(); Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(MoilColor.textTertiary) }.padding(14) }
}
