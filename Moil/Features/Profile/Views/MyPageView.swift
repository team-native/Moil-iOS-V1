import SwiftUI

struct MyPageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    @AppStorage("moilDarkMode") private var isDarkMode = true
    @AppStorage(MoilLocalAccount.nameKey) private var storedName = ""
    @AppStorage(MoilLocalAccount.colorKey) private var profileColorId = ""
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
    /// 회원가입 때 저장한 이름을 먼저 쓰고, 없으면 서버 닉네임을 씁니다.
    private var myName: String {
        MoilLocalAccount.displayName(fallback: groupStore.groups
            .compactMap { groupStore.members(for: $0.id).first(where: \.isMe)?.nickname }
            .first)
    }

    @MainActor
    private var myColor: Color {
        let colorId = profileColorId.isEmpty
            ? groupStore.groups.compactMap { groupStore.members(for: $0.id).first(where: \.isMe)?.colorId }.first
            : profileColorId
        return colorId.map(MoilAvatarColor.color(for:)) ?? MoilAvatarColor.green
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Button { onAccountRoute?(.profileEdit) } label: {
                    HStack(spacing: 14) {
                        MoilAvatar(color: myColor, size: 56)
                        Text(myName)
                            .font(MoilTypography.bold(21))
                            .foregroundStyle(MoilColor.textPrimary)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(MoilColor.textTertiary)
                    }
                    .padding(.trailing, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
                    MoilToggle(title: "다크 모드", isOn: $isDarkMode).padding(.horizontal, 14).frame(height: 48)
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
        .task(id: groupStore.selectedGroupId) {
            // 프로필 이름과 색을 서버 값으로 보여주기 위해 멤버를 불러옵니다.
            guard let groupId = groupStore.selectedGroupId else { return }
            _ = try? await groupStore.loadMembers(groupId: groupId, using: sessionStore.service())
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
    case profileEdit
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
        case .profileEdit:
            ProfileEditView(onClose: onClose)
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
    @State private var isChanging = false

    private var canSubmit: Bool {
        !origin.isEmpty && newPassword.count >= 8 && newPassword == confirmation && !isChanging
    }

    var body: some View {
        VStack(spacing: 0) {
        MoilInlineHeader(title: "비밀번호 변경", onBack: onClose)
        ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MoilTabScreenMetrics.fieldSpacing) {
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
        .moilLoading(isChanging)
    }

    private func changePassword() async {
        isChanging = true
        defer { isChanging = false }
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

    private var canDelete: Bool {
        email.contains("@") && !password.isEmpty && !isDeleting
    }

    var body: some View {
        VStack(spacing: 0) {
        MoilInlineHeader(title: "회원 탈퇴", onBack: onClose)
        ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MoilTabScreenMetrics.fieldSpacing) {
                    MoilFormStack {
                        MoilValidatedField { MoilTextField(placeholder: "이메일", text: $email, contentType: .emailAddress, keyboardType: .emailAddress) }
                        MoilValidatedField { MoilTextField(placeholder: "비밀번호", text: $password, isSecure: true, contentType: .password) }
                    }
                    MoilToggle(title: "그룹 데이터 유지", isOn: $leftData)
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
            MoilButton(title: "회원 탈퇴", isEnabled: canDelete) {
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
        .moilLoading(isDeleting)
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

/// 마이페이지 > 프로필 변경입니다. 이름은 서버에 저장하고, 색은 기기에 저장합니다.
private struct ProfileEditView: View {
    let onClose: () -> Void
    @EnvironmentObject private var sessionStore: MoilSessionStore
    @EnvironmentObject private var groupStore: MoilGroupStore
    @AppStorage(MoilLocalAccount.nameKey) private var storedName = ""
    @AppStorage(MoilLocalAccount.colorKey) private var profileColorId = ""
    @State private var name = ""
    @State private var selectedColor = MoilAvatarColor.green
    @State private var message: String?
    @State private var isSaving = false
    private let colors = [MoilAvatarColor.green, MoilAvatarColor.purple, MoilAvatarColor.pink]

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    var body: some View {
        VStack(spacing: 0) {
            MoilInlineHeader(title: "프로필 변경", onBack: onClose)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    MoilAvatar(color: selectedColor, size: 76)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 24)

                    MoilFormStack {
                        MoilValidatedField(label: "이름") {
                            MoilTextField(placeholder: "이름 입력", text: $name, contentType: .name)
                        }
                    }

                    Text("내 프로필 색 선택")
                        .font(MoilTypography.semibold(12))
                        .foregroundStyle(MoilColor.textTertiary)
                        .padding(.top, MoilTabScreenMetrics.fieldSpacing)
                        .padding(.bottom, 18)
                    MoilColorPicker(colors: colors, selection: $selectedColor)

                    if let message {
                        Text(message)
                            .font(MoilTypography.regular(12))
                            .foregroundStyle(MoilColor.error)
                            .padding(.top, 14)
                    }
                }
                .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
                .safeAreaPadding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .safeAreaInset(edge: .bottom) {
            MoilButton(title: "저장", isEnabled: canSubmit) { Task { await save() } }
                .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MoilColor.background.ignoresSafeArea())
        .moilLoading(isSaving)
        .onAppear {
            name = storedName
            if name.isEmpty {
                name = groupStore.groups
                    .compactMap { groupStore.members(for: $0.id).first(where: \.isMe)?.nickname }
                    .first ?? ""
            }
            if !profileColorId.isEmpty {
                selectedColor = MoilAvatarColor.color(for: profileColorId)
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let profile = try await sessionStore.service().updateProfileName(trimmed)
            storedName = profile.name
            profileColorId = MoilAvatarColor.id(for: selectedColor)
            onClose()
        } catch {
            message = error.localizedDescription
        }
    }
}
