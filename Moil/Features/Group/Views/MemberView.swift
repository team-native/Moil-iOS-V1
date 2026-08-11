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
        currentMembers.map { ($0.nickname, isAdministrator($0) ? "관리자" : "멤버", MoilAvatarColor.color(for: $0.colorId)) }
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
                MoilScreenHeader(title: "멤버", subtitle: selectedGroup?.name)
                ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    groupPicker
                    memberList
                    inviteCodeCard
                    groupSettings
                    administratorSettings
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
            .sheet(isPresented: $isEditingPermissions) {
                PermissionEditorView(members: currentMembers) { updatedRoles in
                    Task { await updateRoles(updatedRoles) }
                }
                    .presentationDetents([.height(327)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isSharingInvite) {
                InviteShareView(inviteCode: inviteCode)
                    .presentationDetents([.height(250)])
                    .presentationDragIndicator(.visible)
            }
            .alert("알림", isPresented: Binding(get: { feedbackMessage != nil }, set: { if !$0 { feedbackMessage = nil } })) {
                Button("확인", role: .cancel) { feedbackMessage = nil }
            } message: {
                Text(feedbackMessage ?? "")
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
            .fullScreenCover(isPresented: $isMyPagePresented) {
                MyPageView()
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
                    .background(selectedGroup?.id == group.id ? MoilColor.primary : MoilColor.background)
                    .clipShape(Capsule())
                }
            }
        }
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
                    UIPasteboard.general.string = inviteCode
                    copied = true
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
                Toggle("알림 받기", isOn: $notificationsEnabled)
                    .padding(14).tint(MoilColor.primary).disabled(isSavingNotification)
                Divider()
                Button("그룹 나가기") { isLeavingGroup = true }
                    .font(MoilTypography.regular(15)).foregroundStyle(MoilColor.error)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                    .popover(isPresented: $isLeavingGroup, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                        LeaveGroupConfirmation(
                            isAdministrator: isAdministratorMode,
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

    @ViewBuilder private var administratorSettings: some View {
        if isAdministratorMode {
            SectionTitle("관리자 설정").padding(.top, 24).padding(.bottom, 8)
            VStack(spacing: 0) {
                AdminSettingRow(title: "그룹 이름 변경") { groupNameDraft = selectedGroup?.name ?? ""; isEditingGroupName = true }
                Divider()
                AdminSettingRow(title: "멤버 권한 설정") { isEditingPermissions = true }
                Divider()
                AdminSettingRow(title: "소셜미디어로 초대 링크 공유") { isSharingInvite = true }
            }
            .background(MoilColor.surface).clipShape(RoundedRectangle(cornerRadius: 20))
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
            feedbackMessage = "그룹을 나가지 못했어요."
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
            feedbackMessage = "멤버 권한을 변경하지 못했어요."
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
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    let inviteCode: String
    var body: some View {
        VStack(spacing: 20) {
            Text("초대 링크 공유").font(MoilTypography.bold(18)).padding(.top, 12)
            Text("친구에게 링크를 보내 그룹에 초대하세요")
                .font(MoilTypography.regular(14)).foregroundStyle(MoilColor.textSecondary)
            HStack(spacing: 24) {
                ForEach([("메시지", "message.fill"), ("카카오톡", "bubble.left.and.bubble.right.fill"), ("링크 복사", "doc.on.doc")], id: \.0) { item in
                    Button {
                        UIPasteboard.general.string = inviteCode
                        copied = true
                    } label: {
                        VStack(spacing: 8) {
                            Circle().fill(MoilColor.primary.opacity(0.12)).frame(width: 52, height: 52)
                                .overlay { Image(systemName: item.1).foregroundStyle(MoilColor.primary) }
                            Text(item.0).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.textPrimary)
                        }
                    }
                }
            }
            Text(copied ? "초대 링크를 복사했습니다" : "")
                .font(MoilTypography.regular(12)).foregroundStyle(MoilColor.primary)
            Spacer()
        }
        .frame(maxWidth: .infinity).background(MoilColor.surface)
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
                TextField("그룹 이름", text: $name)
                    .font(MoilTypography.regular(15))
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(MoilColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                HStack(spacing: 8) {
                    Button("취소", action: onCancel)
                        .font(MoilTypography.semibold(14))
                        .foregroundStyle(MoilColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(MoilColor.surface)
                        .overlay { RoundedRectangle(cornerRadius: 10).stroke(MoilColor.textTertiary.opacity(0.3), lineWidth: 1) }
                    Button("저장", action: onSave)
                        .font(MoilTypography.semibold(14))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(MoilColor.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(20)
            .frame(maxWidth: 320)
            .background(MoilColor.surface)
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

                Button("권한 넘기기", action: onTransfer)
                    .font(MoilTypography.semibold(14))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(selection == nil ? MoilColor.textTertiary.opacity(0.45) : MoilColor.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .disabled(selection == nil)
                    .padding(.top, 16)
                Button("취소", action: onCancel)
                    .font(MoilTypography.semibold(14))
                    .foregroundStyle(MoilColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .padding(.horizontal, 20)
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
                Button("관리자 권한 이전", action: onTransfer)
                    .font(MoilTypography.semibold(14))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(MoilColor.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 16)
            } else {
                Button("그룹 나가기", action: onLeave)
                    .font(MoilTypography.semibold(14))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(MoilColor.error)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 16)
            }
            Button("취소", action: onCancel)
                .font(MoilTypography.semibold(14))
                .foregroundStyle(MoilColor.textSecondary)
                .frame(maxWidth: .infinity).frame(height: 40)
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
                .font(MoilTypography.bold(17))
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)
            ForEach(members) { member in
                HStack(spacing: 12) {
                    MoilAvatar(color: MoilAvatarColor.color(for: member.colorId), size: 34)
                    Text(member.nickname)
                        .font(MoilTypography.semibold(15))
                        .lineLimit(1)
                    Spacer(minLength: 12)
                    Picker("권한", selection: Binding(get: { administrators.contains(member.id) }, set: { enabled in
                        if enabled {
                            administrators.insert(member.id)
                        } else {
                            administrators.remove(member.id)
                        }
                    })) {
                        Text("멤버").tag(false)
                        Text("관리자").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 132)
                }
                .padding(.horizontal, 20)
                .frame(height: 56)
                if member.id != members.last?.id { Divider().padding(.leading, 66).padding(.trailing, 20) }
            }
            Button("완료") {
                onSave(members.compactMap { member in
                    guard let userId = Int(member.id) else { return nil }
                    return MemberRoleRequest(userId: userId, role: administrators.contains(member.id) ? "admin" : "member")
                })
            }
                .font(MoilTypography.bold(14)).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(MoilColor.primary).clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(20)
        }
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
    var body: some View { Text(title).font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary) }
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
