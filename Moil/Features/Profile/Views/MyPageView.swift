import SwiftUI

struct MyPageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    @AppStorage("moilDarkMode") private var isDarkMode = false
    @State private var isGroupDetailPresented = false
    @State private var isLogoutConfirmationPresented = false
    @State private var isMemberPresented = false
    @State private var isJoinGroupPresented = false
    @State private var isJoinProfilePresented = false
    @State private var isAccountSecurityPresented = false
    let onCreateGroup: () -> Void
    let onLeaveGroup: () -> Void
    let onLogout: () -> Void
    let onTabSelect: ((MoilTab) -> Void)?
    let showsTabBar: Bool

    init(onCreateGroup: @escaping () -> Void = {}, onLeaveGroup: @escaping () -> Void = {}, onLogout: @escaping () -> Void = {}, onTabSelect: ((MoilTab) -> Void)? = nil, showsTabBar: Bool = true) {
        self.onCreateGroup = onCreateGroup
        self.onLeaveGroup = onLeaveGroup
        self.onLogout = onLogout
        self.onTabSelect = onTabSelect
        self.showsTabBar = showsTabBar
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
                            groupStore.selectGroup(group.id)
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
                Button("계정 보안") { isAccountSecurityPresented = true }
                    .font(MoilTypography.semibold(15)).foregroundStyle(MoilColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                    .background(MoilColor.surface).clipShape(RoundedRectangle(cornerRadius: 18))
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
            if showsTabBar {
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
        .sheet(isPresented: $isAccountSecurityPresented) {
            AccountSecurityView { email, password, leftData in
                await deleteAccount(email: email, password: password, leftData: leftData)
            }
            .presentationDetents([.large])
        }
        .alert("로그아웃할까요?", isPresented: $isLogoutConfirmationPresented) {
            Button("취소", role: .cancel) { }
            Button("로그아웃", role: .destructive, action: onLogout)
        } message: {
            Text("로그아웃하면 로그인 화면으로 돌아갑니다.")
        }
    }

    private func deleteAccount(email: String, password: String, leftData: Bool) async -> String? {
        do {
            try await sessionStore.service().deleteAccount(email: email, password: password, leftData: leftData)
            sessionStore.clear()
            groupStore.reset()
            onLogout()
            return nil
        } catch { return error.localizedDescription }
    }
}

#Preview("마이페이지") {
    MyPageView()
}

private struct AccountSecurityView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: MoilSessionStore
    @State private var origin = ""
    @State private var newPassword = ""
    @State private var confirmation = ""
    @State private var email = ""
    @State private var deletionPassword = ""
    @State private var leftData = false
    @State private var message: String?
    let onDelete: (String, String, Bool) async -> String?
    @State private var isDeleting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("비밀번호 변경").font(MoilTypography.bold(20))
                    SecureField("현재 비밀번호", text: $origin).accountField()
                    SecureField("새 비밀번호", text: $newPassword).accountField()
                    SecureField("새 비밀번호 확인", text: $confirmation).accountField()
                    Button("비밀번호 변경") { Task { await changePassword() } }
                        .accountButton(enabled: newPassword.count >= 8 && newPassword == confirmation)
                    Divider().padding(.vertical, 16)
                    Text("회원 탈퇴").font(MoilTypography.bold(20)).foregroundStyle(MoilColor.error)
                    Text("탈퇴하면 계정에 접근할 수 없어요.").font(MoilTypography.regular(13)).foregroundStyle(MoilColor.textSecondary)
                    TextField("이메일", text: $email).accountField()
                    SecureField("비밀번호", text: $deletionPassword).accountField()
                    Toggle("그룹 데이터 유지", isOn: $leftData).tint(MoilColor.primary)
                    Button("회원 탈퇴", role: .destructive) {
                        Task {
                            isDeleting = true
                            message = await onDelete(email, deletionPassword, leftData)
                            isDeleting = false
                            if message == nil { dismiss() }
                        }
                    }
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(MoilColor.error.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 14)).disabled(isDeleting)
                    if let message { Text(message).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.error) }
                }
                .padding(20)
            }
            .background(MoilColor.background)
            .navigationTitle("계정 보안")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기", action: dismiss.callAsFunction) } }
        }
    }

    private func changePassword() async {
        do {
            try await sessionStore.service().changePassword(origin: origin, newPassword: newPassword, confirmation: confirmation)
            message = "비밀번호를 변경했어요."
            origin = ""; newPassword = ""; confirmation = ""
        } catch { message = "비밀번호를 변경하지 못했어요." }
    }
}

private extension View {
    func accountField() -> some View {
        padding(.horizontal, 14).frame(height: 50).background(MoilColor.surface).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func accountButton(enabled: Bool) -> some View {
        font(MoilTypography.bold(15)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 50)
            .background(enabled ? MoilColor.primary : MoilColor.primary.opacity(0.7)).clipShape(RoundedRectangle(cornerRadius: 14)).disabled(!enabled)
    }
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
