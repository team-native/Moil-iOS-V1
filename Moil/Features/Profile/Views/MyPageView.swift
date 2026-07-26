import SwiftUI

struct MyPageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isDarkMode = false
    @State private var isGroupDetailPresented = false
    @State private var isLogoutConfirmationPresented = false
    let onCreateGroup: () -> Void

    init(onCreateGroup: @escaping () -> Void = {}) {
        self.onCreateGroup = onCreateGroup
    }
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("마이페이지")
                        .font(MoilTypography.bold(26))
                    Spacer()
                }
                .padding(.bottom, 28)

                HStack(spacing: 14) {
                    MoilAvatar(color: Color("AvatarGreen"), size: 56)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("나").font(MoilTypography.bold(21))
                    }
                }
                .padding(.bottom, 28)

                GroupSection(title: "내 그룹") {
                    Button { isGroupDetailPresented = true } label: { GroupRow("우리 가족", .blue) }
                    Divider(); Button { isGroupDetailPresented = true } label: { GroupRow("대학 동기", .green) }
                    Divider(); Button { isGroupDetailPresented = true } label: { GroupRow("회사 팀", .green) }
                    Divider()
                    Button(action: onCreateGroup) {
                        Label("새 그룹 만들기", systemImage: "plus")
                            .font(MoilTypography.semibold(15))
                            .foregroundStyle(MoilColor.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                    }
                }
                .padding(.bottom, 28)
                GroupSection(title: "환경설정") {
                    Toggle("다크 모드", isOn: $isDarkMode).padding(14).tint(MoilColor.primary)
                }
                .padding(.bottom, 16)
                Button("로그아웃") { isLogoutConfirmationPresented = true }
                    .font(MoilTypography.semibold(15)).foregroundStyle(MoilColor.error)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 16).safeAreaPadding(.top, 18).padding(.bottom, 32)
        }
        .background(MoilColor.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MoilTabBar(selected: .profile) { tab in
                if tab == .calendar { dismiss() }
            }
        }
        .sheet(isPresented: $isGroupDetailPresented) { GroupDetailView() }
        .confirmationDialog("로그아웃할까요?", isPresented: $isLogoutConfirmationPresented, titleVisibility: .visible) {
            Button("로그아웃", role: .destructive, action: dismiss.callAsFunction)
            Button("취소", role: .cancel) { }
        }
    }
}

#Preview("마이페이지") {
    MyPageView()
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
