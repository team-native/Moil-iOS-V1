import SwiftUI

struct MyPageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @AppStorage("moilDarkMode") private var isDarkMode = false
    @State private var isGroupDetailPresented = false
    @State private var isLogoutConfirmationPresented = false
    @State private var isMemberPresented = false
    @State private var isJoinGroupPresented = false
    @State private var isJoinProfilePresented = false
    let onCreateGroup: () -> Void
    let onLeaveGroup: () -> Void
    let onTabSelect: ((MoilTab) -> Void)?

    init(onCreateGroup: @escaping () -> Void = {}, onLeaveGroup: @escaping () -> Void = {}, onTabSelect: ((MoilTab) -> Void)? = nil) {
        self.onCreateGroup = onCreateGroup
        self.onLeaveGroup = onLeaveGroup
        self.onTabSelect = onTabSelect
    }
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 14) {
                    MoilAvatar(color: MoilAvatarColor.green, size: 56)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("나").font(MoilTypography.bold(21))
                    }
                }
                .padding(.bottom, 20)

                GroupSection(title: "내 그룹") {
                    ForEach(groupStore.groups) { group in
                        Button {
                            groupStore.selectGroup(group.name)
                            isGroupDetailPresented = true
                        } label: {
                            GroupRow(group.name, group.color)
                        }
                        if group.id != groupStore.groups.last?.id { Divider() }
                    }
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
                    .background(MoilColor.surface).clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 16).safeAreaPadding(.top, 8).padding(.bottom, 32)
        }
        .background(MoilColor.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MoilTabBar(selected: .profile) { tab in
                if let onTabSelect {
                    onTabSelect(tab)
                } else {
                    switch tab {
                    case .calendar:
                        dismiss()
                    case .members:
                        isMemberPresented = true
                    case .create:
                        isJoinGroupPresented = true
                    case .profile:
                        break
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isGroupDetailPresented) {
            GroupDetailView {
                isGroupDetailPresented = false
                onLeaveGroup()
            }
        }
        .fullScreenCover(isPresented: $isMemberPresented) {
            MemberView()
        }
        .fullScreenCover(isPresented: $isJoinGroupPresented) {
            GroupJoinCodeView {
                isJoinGroupPresented = false
                isJoinProfilePresented = true
            }
        }
        .fullScreenCover(isPresented: $isJoinProfilePresented) {
            GroupJoinProfileView { isJoinProfilePresented = false }
        }
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
    var body: some View { VStack(alignment: .leading, spacing: 8) { Text(title).font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary); VStack(spacing: 0) { content }.background(MoilColor.surface).clipShape(RoundedRectangle(cornerRadius: 18)) } }
}
private struct GroupRow: View {
    let title: String; let color: Color
    init(_ title: String, _ color: Color) { self.title = title; self.color = color }
    var body: some View { HStack { Circle().fill(color).frame(width: 8, height: 8); Text(title).font(MoilTypography.semibold(15)); Spacer(); Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(MoilColor.textTertiary) }.padding(14) }
}
