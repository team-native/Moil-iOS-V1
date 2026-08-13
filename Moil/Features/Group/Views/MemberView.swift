import SwiftUI
import UIKit

struct MemberView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    var onTabSelect: ((MoilTab) -> Void)? = nil
    var onCreateGroup: (() -> Void)? = nil
    var showsTabBar = true
    @State private var selectedGroupId: String?
    @State private var remoteMembers: [MoilRemoteMember] = []
    @State private var loadedMembersGroupID: String?
    @State private var notificationsEnabled = true
    @State private var copied = false
    @State private var isEditingGroupName = false
    @State private var isEditingPermissions = false
    @State private var isSharingInvite = false
    @State private var isTransferringAdmin = false
    @State private var groupNameDraft = ""
    @State private var newAdministrator: String?
    @State private var isLeavingGroup = false
    @State private var feedbackMessage: String?
    @State private var isJoinGroupPresented = false
    @State private var isJoinProfilePresented = false
    @State private var isMyPagePresented = false
    @State private var isCreateGroupPresented = false
    @State private var isSavingNotification = false

    private var selectedGroup: MoilGroup? {
        groupStore.groups.first { $0.id == selectedGroupId } ?? groupStore.selectedGroup
    }

    private var currentMembers: [MoilRemoteMember] {
        let loaded = loadedMembersGroupID == selectedGroup?.id ? remoteMembers : []
        return loaded.isEmpty ? groupStore.members(for: selectedGroup?.id) : loaded
    }

    private var members: [(String, String, Color)] {
        currentMembers.map { ($0.displayName, isAdministrator($0) ? "관리자" : "멤버", MoilAvatarColor.color(for: $0.colorId)) }
    }

    /// 그룹 응답의 역할을 먼저 쓰고, 멤버 응답이 도착하면 그쪽으로 확정합니다.
    private var isAdministratorMode: Bool {
        if currentMembers.contains(where: { $0.isMe }) {
            return currentMembers.contains { $0.isMe && isAdministrator($0) }
        }
        return selectedGroup?.isAdministrator ?? false
    }

    private func isAdministrator(_ member: MoilRemoteMember) -> Bool {
        ["OWNER", "ADMIN"].contains(member.role.uppercased())
    }

    private var inviteCode: String {
        selectedGroup?.inviteCode ?? ""
    }

    var body: some View {
        screenContent
    }

    private var screenContent: some View {
        VStack(spacing: 0) {
            if groupStore.groups.isEmpty {
                EmptyCalendarView(
                    onJoin: {
                        if let onTabSelect { onTabSelect(.create) }
                        else { isJoinGroupPresented = true }
                    },
                    onCreate: {
                        if let onCreateGroup { onCreateGroup() }
                        else { isCreateGroupPresented = true }
                    }
                )
            } else {
                MoilScreenHeader(title: "멤버")
                ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    groupPicker
                    memberList
                    inviteCodeCard
                    groupSettings
                }
                .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
                .padding(.bottom, 32)
            }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MoilColor.background)
        .moilTabScreenLayout(selected: .members, isTabBarVisible: showsTabBar) { tab in
            if let onTabSelect { onTabSelect(tab); return }
            switch tab {
            case .calendar: dismiss()
            case .members: break
            case .create: isJoinGroupPresented = true
            case .profile: isMyPagePresented = true
            }
        }
        .overlay {
            if isEditingGroupName {
                GroupNameEditor(name: $groupNameDraft) {
                    Task { await renameSelectedGroup() }
                } onCancel: {
                    isEditingGroupName = false
                }
            } else if isTransferringAdmin {
                AdministratorTransferEditor(selection: $newAdministrator, candidates: currentMembers) {
                    Task { await transferAdministrator() }
                } onCancel: {
                    isTransferringAdmin = false
                }
            }
        }
            .moilBottomSheet(
                isPresented: $isEditingPermissions,
                height: CGFloat(180 + currentMembers.count * 52),
                background: MoilColor.surface
            ) {
                PermissionEditorView(members: currentMembers) { updatedRoles in
                    Task { await updateRoles(updatedRoles) }
                }
            }
            .moilBottomSheet(isPresented: $isSharingInvite, height: 210, background: MoilColor.surface) {
                InviteShareView(inviteCode: inviteCode)
            }
            .alert("알림", isPresented: Binding(get: { feedbackMessage != nil }, set: { if !$0 { feedbackMessage = nil } })) {
                Button("확인", role: .cancel) { feedbackMessage = nil }
            } message: {
                Text(feedbackMessage ?? "")
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
            .fullScreenCover(isPresented: $isMyPagePresented) {
                MyPageView(showsTabBar: false)
            }
            .fullScreenCover(isPresented: $isCreateGroupPresented) {
                CreateGroupView()
            }
            .task(id: selectedGroup?.id) {
                await loadMembers()
            }
            .onChange(of: notificationsEnabled) { _, enabled in
                guard !isSavingNotification, let groupId = selectedGroup?.id else { return }
                Task { await saveNotification(enabled: enabled, groupId: groupId) }
            }
    }

    private var groupPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(groupStore.groups) { group in
                    Button(group.name) {
                        selectedGroupId = group.id
                        groupStore.selectGroup(group.id)
                    }
                    .font(MoilTypography.semibold(13))
                    .foregroundStyle(selectedGroup?.id == group.id ? .white : MoilColor.textSecondary)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(selectedGroup?.id == group.id ? MoilColor.primary : MoilColor.surface)
                    .clipShape(Capsule())
                    .contentShape(Capsule())
                }
            }
            .padding(.vertical, 2)
        }
        .frame(height: 38)
        .padding(.bottom, 28)
    }

    private var memberList: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle("구성원").padding(.bottom, 8)
            VStack(spacing: 0) {
                ForEach(members.indices, id: \.self) { index in
                    MemberRow(member: members[index])
                    if index < members.count - 1 { Divider().padding(.leading, 64) }
                }
            }
            .padding(.vertical, 4)
            .background(MoilColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding(.bottom, 24)
    }

    private var inviteCodeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("초대 코드").font(MoilTypography.semibold(13))
            HStack {
                Text(inviteCode).font(MoilTypography.bold(19)).tracking(1)
                Spacer()
                Button(copied ? "복사됨" : "복사") {
                    copyInviteCode()
                }
                    .font(MoilTypography.bold(12)).foregroundStyle(.white)
                    .padding(.horizontal, 12).frame(height: 34)
                    .background(MoilColor.primary).clipShape(Capsule())
            }
        }
        .padding(16).background(MoilColor.surface).clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.bottom, 24)
    }

    private var groupSettings: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle("그룹 설정").padding(.bottom, 8)
            VStack(spacing: 0) {
                MoilToggle(title: "알림 받기", isOn: $notificationsEnabled)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                // 관리자일 때만 관리자용 항목이 같은 카드 안에 이어집니다.
                if isAdministratorMode {
                    Divider()
                    AdminSettingRow(title: "그룹 이름 변경") { groupNameDraft = selectedGroup?.name ?? ""; isEditingGroupName = true }
                    Divider()
                        AdminSettingRow(title: "멤버 권한 설정") { isEditingPermissions = true }
                    Divider()
                        AdminSettingRow(title: "소셜미디어로 초대 링크 공유") { isSharingInvite = true }
                }
                Divider()
                Button("그룹 나가기") { isLeavingGroup = true }
                    .font(MoilTypography.regular(15)).foregroundStyle(MoilColor.error)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                    .popover(isPresented: $isLeavingGroup, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                        LeaveGroupConfirmation(
                            // 나 혼자인 그룹은 넘길 사람이 없으므로 바로 나갈 수 있게 합니다.
                            isAdministrator: isAdministratorMode && currentMembers.count > 1,
                            onLeave: {
                                isLeavingGroup = false
                                Task { await leaveSelectedGroup() }
                            },
                            onTransfer: {
                                isLeavingGroup = false
                                newAdministrator = nil
                                isTransferringAdmin = true
                            },
                            onCancel: { isLeavingGroup = false }
                        )
                        .presentationCompactAdaptation(.popover)
                    }
            }
            .background(MoilColor.surface).clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    /// 복사 뒤에는 다시 복사할 수 있다는 걸 알 수 있도록 잠시 뒤 원래 문구로 되돌립니다.
    private func copyInviteCode() {
        guard !inviteCode.isEmpty else { return }
        UIPasteboard.general.string = inviteCode
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
    }

    private func loadMembers() async {
        guard let groupId = selectedGroup?.id else { remoteMembers = []; return }
        do {
            remoteMembers = try await groupStore.loadMembers(groupId: groupId, using: sessionStore.service())
            loadedMembersGroupID = groupId
        } catch {
            // 요청이 취소된 경우에는 이미 보여주고 있는 구성원을 그대로 둡니다.
            guard !error.isRequestCancellation else { return }
            remoteMembers = groupStore.members(for: groupId)
            loadedMembersGroupID = groupId
        }
    }

    private func saveNotification(enabled: Bool, groupId: String) async {
        isSavingNotification = true
        defer { isSavingNotification = false }
        do {
            try await sessionStore.service().setNotification(groupId: groupId, enabled: enabled)
        } catch {
            notificationsEnabled = !enabled
            feedbackMessage = "알림 설정을 저장하지 못했어요."
        }
    }

    private func leaveSelectedGroup() async {
        guard let group = selectedGroup else { return }
        do {
            try await sessionStore.service().leaveGroup(groupId: group.id)
            groupStore.removeGroup(group.id)
            remoteMembers = []
            feedbackMessage = "\(group.name) 그룹에서 나왔어요."
        } catch {
            feedbackMessage = error.localizedDescription
        }
    }

    private func transferAdministrator() async {
        guard let groupId = selectedGroup?.id,
              let nickname = newAdministrator,
              let target = currentMembers.first(where: { $0.nickname == nickname }) else { return }
        guard let targetUserId = Int(target.id) else { return }
        do {
            try await sessionStore.service().transferAdmin(groupId: groupId, targetUserId: targetUserId)
            isTransferringAdmin = false
            feedbackMessage = "\(target.nickname)에게 관리자 권한을 이전했어요."
            await loadMembers()
        } catch {
            feedbackMessage = "관리자 권한을 이전하지 못했어요."
        }
    }

    private func updateRoles(_ roles: [MemberRoleRequest]) async {
        guard let groupId = selectedGroup?.id else { return }
        do {
            try await sessionStore.service().updateMemberRoles(groupId: groupId, members: roles)
            isEditingPermissions = false
            await loadMembers()
        } catch {
            feedbackMessage = error.localizedDescription
        }
    }

    private func renameSelectedGroup() async {
        guard let groupId = selectedGroup?.id else { return }
        let name = groupNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            feedbackMessage = "그룹 이름을 입력해주세요."
            return
        }
        do {
            try await groupStore.renameGroup(id: groupId, name: name, using: sessionStore.service())
            isEditingGroupName = false
            feedbackMessage = "그룹 이름을 변경했어요."
        } catch {
            feedbackMessage = "그룹 이름을 변경하지 못했어요."
        }
    }
}

#Preview("멤버 관리") {
    MemberView()
}

private struct InviteShareView: View {
    @State private var copied = false
    @State private var shareTarget: MoilShareTarget?
    @State private var cannotSendMessage = false
    let inviteCode: String

    private var inviteLink: String { "https://moil.app/join/\(inviteCode)" }

    /// 공유 앱에 보낼 문구입니다.
    private var shareText: String {
        "모일에서 함께 일정을 맞춰요.\n초대 링크: \(inviteLink)"
    }

    private func copyInviteLink() {
        UIPasteboard.general.string = inviteLink
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
    }

    /// 피그마 기준: 제목·링크는 왼쪽 정렬, 공유 버튼 3개는 가운데 정렬이고
    /// 내용은 시트 아래쪽에 붙습니다.
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            Text("초대 링크 공유")
                .font(MoilTypography.bold(20))
                .foregroundStyle(MoilColor.textPrimary)
            Text(copied ? "링크를 복사했어요" : inviteLink)
                .font(MoilTypography.regular(14))
                .foregroundStyle(copied ? MoilColor.primary : MoilColor.textSecondary)
                .lineLimit(1)
                .padding(.top, 8)

            HStack(spacing: 17) {
                shareButton("카카오톡", color: Color(red: 0.984, green: 0.898, blue: 0.000), icon: "message.fill", iconColor: .black) {
                    shareTarget = .activity
                }
                shareButton("메시지", color: Color(red: 0.361, green: 0.553, blue: 0.937), icon: "message.fill", iconColor: .white) {
                    if MoilMessageComposer.canSend {
                        shareTarget = .message
                    } else {
                        cannotSendMessage = true
                    }
                }
                shareButton("링크 복사", color: MoilColor.surface, icon: "doc.on.doc", iconColor: MoilColor.textPrimary, hasBorder: true) {
                    copyInviteLink()
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 20)
            .padding(.bottom, 26)
        }
        .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .background(MoilColor.surface)
        .sheet(item: $shareTarget) { target in
            switch target {
            case .message:
                MoilMessageComposer(body: shareText) { shareTarget = nil }
                    .ignoresSafeArea()
            case .activity:
                MoilActivitySheet(items: [shareText]) { shareTarget = nil }
                    .ignoresSafeArea()
            }
        }
        .alert("메시지를 보낼 수 없어요", isPresented: $cannotSendMessage) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("이 기기에서는 메시지를 보낼 수 없어요. 링크를 복사해 다른 앱으로 보내주세요.")
        }
    }

    private func shareButton(
        _ title: String,
        color: Color,
        icon: String,
        iconColor: Color,
        hasBorder: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                    .overlay { Circle().stroke(MoilColor.emptyStateBorder, lineWidth: hasBorder ? 1 : 0) }
                    .overlay { Image(systemName: icon).font(.system(size: 19, weight: .medium)).foregroundStyle(iconColor) }
                Text(title)
                    .font(MoilTypography.regular(12))
                    .foregroundStyle(MoilColor.textSecondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct GroupNameEditor: View {
    @Binding var name: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.42).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                Text("그룹 이름 변경")
                    .font(MoilTypography.bold(18))
                MoilTextField(placeholder: "그룹 이름", text: $name)
                HStack(spacing: 8) {
                    MoilButton(title: "취소", style: .outline, action: onCancel)
                    MoilButton(title: "저장", action: onSave)
                }
            }
            .padding(20)
            .frame(maxWidth: 320)
            // 입력 칸과 같은 색이면 칸이 안 보여서, 다이얼로그는 한 단계 어두운 배경을 씁니다.
            .background(MoilColor.background)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 32)
        }
    }
}

private struct AdministratorTransferEditor: View {
    @Binding var selection: String?
    let candidates: [MoilRemoteMember]
    let onTransfer: () -> Void
    let onCancel: () -> Void

    private var eligibleCandidates: [MoilRemoteMember] {
        candidates.filter { !$0.isMe }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.42).ignoresSafeArea()
            VStack(spacing: 0) {
                Text("관리자 권한을 넘겨주세요")
                    .font(MoilTypography.bold(18))
                    .padding(.top, 24)
                Text("넘겨줄 멤버를 선택해주세요")
                    .font(MoilTypography.regular(13))
                    .foregroundStyle(MoilColor.textSecondary)
                    .padding(.top, 6)
                    .padding(.bottom, 18)

                VStack(spacing: 8) {
                    ForEach(eligibleCandidates, id: \.id) { candidate in
                        Button { selection = candidate.nickname } label: {
                            HStack(spacing: 12) {
                                MoilAvatar(color: MoilAvatarColor.color(for: candidate.colorId), size: 28)
                                Text(candidate.nickname).font(MoilTypography.semibold(15))
                                Spacer()
                                Image(systemName: selection == candidate.nickname ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(selection == candidate.nickname ? MoilColor.primary : MoilColor.textTertiary)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(MoilColor.background)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .foregroundStyle(MoilColor.textPrimary)
                    }
                }

                MoilButton(title: "권한 넘기기", isEnabled: selection != nil, action: onTransfer)
                    .padding(.top, 16)
                MoilButton(title: "취소", style: .text, action: onCancel)
            }
            .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
            .padding(.bottom, 12)
            .frame(maxWidth: 320)
            .background(MoilColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 32)
        }
    }
}

private struct LeaveGroupConfirmation: View {
    let isAdministrator: Bool
    let onLeave: () -> Void
    let onTransfer: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(isAdministrator ? "관리자는 바로 나갈 수 없어요" : "그룹을 나갈까요?")
                .font(MoilTypography.bold(16))
            Text(isAdministrator
                 ? "다른 멤버에게 관리자 권한을 넘긴 뒤에 나갈 수 있어요."
                 : "나가면 그룹의 일정과 멤버 정보를 더 이상 볼 수 없어요.")
                .font(MoilTypography.regular(13))
                .foregroundStyle(MoilColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            if isAdministrator {
                MoilButton(title: "관리자 권한 이전", height: 44, action: onTransfer)
                    .padding(.top, 16)
            } else {
                MoilButton(title: "그룹 나가기", height: 44, action: onLeave)
                    .padding(.top, 16)
            }
            MoilButton(title: "취소", style: .text, action: onCancel)
        }
        .padding(18)
        .frame(width: 260)
        .background(MoilColor.surface)
    }
}

private struct PermissionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let members: [MoilRemoteMember]
    let onSave: ([MemberRoleRequest]) -> Void
    @State private var administrators: Set<String>

    init(members: [MoilRemoteMember], onSave: @escaping ([MemberRoleRequest]) -> Void) {
        self.members = members
        self.onSave = onSave
        _administrators = State(initialValue: Set(members.filter { ["OWNER", "ADMIN"].contains($0.role.uppercased()) }.map(\.id)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("멤버 권한 설정")
                .font(MoilTypography.bold(20))
                .foregroundStyle(MoilColor.textPrimary)
                .padding(.top, 26)
                .padding(.bottom, 18)

            ForEach(members) { member in
                HStack(spacing: 12) {
                    MoilAvatar(color: MoilAvatarColor.color(for: member.colorId), size: 28)
                    Text(member.displayName)
                        .font(MoilTypography.semibold(15))
                        .foregroundStyle(MoilColor.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 12)
                    RolePicker(isEditable: !member.isMe, isAdministrator: Binding(
                        get: { administrators.contains(member.id) },
                        set: { enabled in
                            var updated = administrators
                            if enabled { updated.insert(member.id) } else { updated.remove(member.id) }
                            var transaction = Transaction()
                            transaction.disablesAnimations = true
                            withTransaction(transaction) { administrators = updated }
                        }
                    ))
                }
                .frame(height: 52)
                if member.id != members.last?.id {
                    Rectangle().fill(MoilColor.emptyStateBorder).frame(height: 1)
                }
            }

            MoilButton(title: "완료") {
                onSave(members.compactMap { member in
                    guard let userId = Int(member.id) else { return nil }
                    return MemberRoleRequest(userId: userId, role: administrators.contains(member.id) ? "admin" : "member")
                })
                dismiss()
            }
            .padding(.top, 22)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(MoilColor.surface)
    }
}

/// 피그마의 관리자/멤버 알약형 선택입니다.
private struct RolePicker: View {
    /// 내 권한은 내가 바꿀 수 없어 보기 전용으로 둡니다.
    var isEditable = true
    @Binding var isAdministrator: Bool

    var body: some View {
        HStack(spacing: 0) {
            segment("관리자", isSelected: isAdministrator) { if isEditable { isAdministrator = true } }
            segment("멤버", isSelected: !isAdministrator) { if isEditable { isAdministrator = false } }
        }
        .opacity(isEditable ? 1 : 0.55)
        .padding(3)
        .background(MoilColor.background)
        .clipShape(Capsule())
    }

    private func segment(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(MoilTypography.bold(13))
                .foregroundStyle(isSelected ? .white : MoilColor.textTertiary)
                .frame(width: 58, height: 30)
                .background(isSelected ? MoilColor.primary : .clear)
                .clipShape(Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct AdminSettingRow: View {
    let title: String
    var action: () -> Void = { }
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(MoilTypography.regular(15)).foregroundStyle(MoilColor.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(MoilColor.textTertiary)
            }
            .padding(14)
        }
    }
}

private struct SectionTitle: View {
    let title: String
    init(_ title: String) { self.title = title }
    /// 아래 카드 안 내용과 같은 자리에서 시작하도록 카드 안쪽 여백만큼 들여씁니다.
    var body: some View {
        Text(title)
            .font(MoilTypography.semibold(12))
            .foregroundStyle(MoilColor.textTertiary)
            .padding(.leading, 16)
    }
}

private struct MemberRow: View {
    let member: (String, String, Color)
    var body: some View {
        HStack(spacing: 12) {
            MoilAvatar(color: member.2, size: 38)
            VStack(alignment: .leading, spacing: 3) {
                Text(member.0).font(MoilTypography.semibold(15))
                Text(member.1).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.textSecondary)
            }
            Spacer()
            Circle().fill(member.2).frame(width: 8, height: 8)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }
}
