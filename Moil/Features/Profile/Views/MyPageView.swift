import SwiftUI

struct MyPageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    @AppStorage("moilDarkMode") private var isDarkMode = true
    @State private var isGroupDetailPresented = false
    @State private var isLogoutConfirmationPresented = false
    @State private var isMemberPresented = false
    @State private var isJoinGroupPresented = false
    @State private var isJoinProfilePresented = false
    let onCreateGroup: () -> Void
    let onLeaveGroup: () -> Void
    let onLogout: () -> Void
    let onTabSelect: ((MoilTab) -> Void)?
    let showsTabBar: Bool
    /// 계정 화면 이동은 상위 네비게이션이 처리합니다.
    var onAccountRoute: ((MoilAccountRoute) -> Void)?

    init(
        onCreateGroup: @escaping () -> Void = {},
        onLeaveGroup: @escaping () -> Void = {},
        onLogout: @escaping () -> Void = {},
        onTabSelect: ((MoilTab) -> Void)? = nil,
        showsTabBar: Bool = true,
        onAccountRoute: ((MoilAccountRoute) -> Void)? = nil
    ) {
        self.onCreateGroup = onCreateGroup
        self.onLeaveGroup = onLeaveGroup
        self.onLogout = onLogout
        self.onTabSelect = onTabSelect
        self.showsTabBar = showsTabBar
        self.onAccountRoute = onAccountRoute
    }
    /// 서버가 내려준 내 닉네임입니다. 아직 못 받았으면 빈 값 대신 기본값을 씁니다.
    private var myName: String {
        groupStore.groups
            .compactMap { groupStore.members(for: $0.id).first(where: \.isMe)?.nickname }
            .first ?? "나"
    }

    @MainActor
    private var myColor: Color {
        groupStore.groups
            .compactMap { groupStore.members(for: $0.id).first(where: \.isMe)?.colorId }
            .first.map(MoilAvatarColor.color(for:)) ?? MoilAvatarColor.green
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 14) {
                    MoilAvatar(color: myColor, size: 56)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(myName).font(MoilTypography.bold(21))
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
                            .contentShape(Rectangle())
                    }
                }
                .padding(.bottom, 28)
                GroupSection(title: "환경설정") {
                    Toggle("다크 모드", isOn: $isDarkMode).padding(14).tint(MoilColor.primary)
                }
                .padding(.bottom, 16)
                GroupSection(title: "계정 보안") {
                    AccountMenuRow(title: "비밀번호 변경") { onAccountRoute?(.passwordChange) }
                    Divider()
                    AccountMenuRow(title: "로그아웃") { isLogoutConfirmationPresented = true }
                    Divider()
                    AccountMenuRow(title: "회원 탈퇴", isDestructive: true) { onAccountRoute?(.accountDeletion) }
                }
            }
            .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
            .safeAreaPadding(.top, MoilTabScreenMetrics.titleTopPadding)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MoilColor.background)
        .moilTabScreenLayout(selected: .profile, isTabBarVisible: showsTabBar) { tab in
            if let onTabSelect {
                onTabSelect(tab)
            } else {
                switch tab {
                case .calendar: dismiss()
                case .members: isMemberPresented = true
                case .create: isJoinGroupPresented = true
                case .profile: break
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
            MemberView(showsTabBar: false)
        }
        .fullScreenCover(isPresented: $isJoinGroupPresented) {
            GroupJoinCodeView(onNext: {
                isJoinGroupPresented = false
                isJoinProfilePresented = true
            }, showsTabBar: false)
        }
        .fullScreenCover(isPresented: $isJoinProfilePresented) {
            GroupJoinProfileView { isJoinProfilePresented = false }
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

enum MoilAccountRoute: Hashable {
    case passwordChange
    case accountDeletion
}

/// 계정 화면은 탭 콘텐츠를 대체해 표시하므로 상위에서 이 래퍼를 그립니다.
struct MoilAccountPage: View {
    let route: MoilAccountRoute
    let onClose: () -> Void
    let onLogout: () -> Void
    @EnvironmentObject private var sessionStore: MoilSessionStore
    @EnvironmentObject private var groupStore: MoilGroupStore

    var body: some View {
        switch route {
        case .passwordChange:
            PasswordChangeView(onClose: onClose)
        case .accountDeletion:
            AccountDeletionView(onClose: onClose) { email, password, leftData in
                do {
                    try await sessionStore.service().deleteAccount(email: email, password: password, leftData: leftData)
                    sessionStore.clear()
                    groupStore.reset()
                    onLogout()
                    return nil
                } catch { return error.localizedDescription }
            }
        }
    }
}

private struct AccountMenuRow: View {
    let title: String
    var isDestructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(MoilTypography.semibold(15))
                    .foregroundStyle(isDestructive ? MoilColor.error : MoilColor.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MoilColor.textTertiary)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PasswordChangeView: View {
    let onClose: () -> Void
    @EnvironmentObject private var sessionStore: MoilSessionStore
    @State private var origin = ""
    @State private var newPassword = ""
    @State private var confirmation = ""
    @State private var message: String?

    private var canSubmit: Bool {
        !origin.isEmpty && newPassword.count >= 8 && newPassword == confirmation
    }

    var body: some View {
        VStack(spacing: 0) {
        MoilInlineHeader(title: "비밀번호 변경", onBack: onClose)
        ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MoilTabScreenMetrics.fieldSpacing) {
                    Text("현재 비밀번호를 확인한 뒤 새 비밀번호로 바꿉니다.")
                        .font(MoilTypography.regular(13))
                        .foregroundStyle(MoilColor.textSecondary)
                    MoilFormStack {
                        MoilValidatedField { MoilTextField(placeholder: "현재 비밀번호", text: $origin, isSecure: true, contentType: .password) }
                        MoilValidatedField { MoilTextField(placeholder: "새 비밀번호", text: $newPassword, isSecure: true, contentType: .newPassword) }
                        MoilValidatedField { MoilTextField(placeholder: "새 비밀번호 확인", text: $confirmation, isSecure: true, contentType: .newPassword) }
                    }
                    if let message {
                        Text(message).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.error)
                    }
                }
                .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
                .safeAreaPadding(.top, 12)
                .padding(.bottom, 32)
        }
        .safeAreaInset(edge: .bottom) {
            MoilButton(title: "비밀번호 변경", isEnabled: canSubmit) { Task { await changePassword() } }
                .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
                .padding(.bottom, 12)
        }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MoilColor.background.ignoresSafeArea())
    }

    private func changePassword() async {
        do {
            try await sessionStore.service().changePassword(origin: origin, newPassword: newPassword, confirmation: confirmation)
            origin = ""; newPassword = ""; confirmation = ""
            onClose()
        } catch { message = "비밀번호를 변경하지 못했어요." }
    }
}

private struct AccountDeletionView: View {
    let onClose: () -> Void
    @State private var email = ""
    @State private var password = ""
    @State private var leftData = false
    @State private var message: String?
    @State private var isDeleting = false
    let onDelete: (String, String, Bool) async -> String?

    var body: some View {
        VStack(spacing: 0) {
        MoilInlineHeader(title: "회원 탈퇴", onBack: onClose)
        ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MoilTabScreenMetrics.fieldSpacing) {
                    Text("탈퇴하면 계정에 접근할 수 없어요.")
                        .font(MoilTypography.regular(13))
                        .foregroundStyle(MoilColor.textSecondary)
                    MoilFormStack {
                        MoilValidatedField { MoilTextField(placeholder: "이메일", text: $email, contentType: .emailAddress, keyboardType: .emailAddress) }
                        MoilValidatedField { MoilTextField(placeholder: "비밀번호", text: $password, isSecure: true, contentType: .password) }
                    }
                    Toggle("그룹 데이터 유지", isOn: $leftData)
                        .font(MoilTypography.regular(15))
                        .tint(MoilColor.primary)
                        .padding(.vertical, 2)
                    if let message {
                        Text(message).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.error)
                    }
                }
                .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
                .safeAreaPadding(.top, 12)
                .padding(.bottom, 32)
        }
        .safeAreaInset(edge: .bottom) {
            MoilButton(title: "회원 탈퇴", isEnabled: !isDeleting) {
                Task {
                    isDeleting = true
                    message = await onDelete(email, password, leftData)
                    isDeleting = false
                    if message == nil { onClose() }
                }
            }
            .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
            .padding(.bottom, 12)
        }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MoilColor.background.ignoresSafeArea())
    }
}

private extension View {

    func accountButton(enabled: Bool, color: Color = MoilColor.primary) -> some View {
        font(MoilTypography.bold(15)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 50)
            .background(enabled ? color : color.opacity(0.7)).clipShape(RoundedRectangle(cornerRadius: 14)).disabled(!enabled)
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
