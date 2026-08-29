import SwiftUI
import Combine

struct MoilGroup: Identifiable {
    let id: String
    var name: String
    var colorId: String?
    var inviteCode: String?
    var myRole: String?

    var color: Color { MoilAvatarColor.color(for: colorId) }

    /// 멤버 응답을 기다리지 않고 관리자 영역을 그릴 수 있도록 그룹 응답의 역할을 그대로 씁니다.
    var isAdministrator: Bool {
        guard let myRole else { return false }
        return ["OWNER", "ADMIN"].contains(myRole.uppercased())
    }

    init(id: String, name: String, colorId: String? = nil, inviteCode: String? = nil, myRole: String? = nil) {
        self.id = id
        self.name = name
        self.colorId = colorId
        self.inviteCode = inviteCode
        self.myRole = myRole
    }

    init(remote: MoilRemoteGroup) {
        self.init(id: remote.id, name: remote.name, colorId: remote.colorId, inviteCode: remote.inviteCode, myRole: remote.myRole)
    }
}

@MainActor
final class MoilGroupStore: ObservableObject {
    @Published private(set) var groups: [MoilGroup] = []
    @Published var selectedGroupId: String?
    @Published var pendingInviteCode: String?
    @Published var pendingInviteGroupName = ""
    @Published var pendingInviteMemberCount = 0
    @Published private(set) var isLoading = false
    @Published private var membersByGroupId: [String: [MoilRemoteMember]] = [:]

    var selectedGroup: MoilGroup? {
        groups.first { $0.id == selectedGroupId } ?? groups.first
    }

    var selectedGroupName: String { selectedGroup?.name ?? "그룹 선택" }

    func members(for groupId: String?) -> [MoilRemoteMember] {
        guard let groupId else { return [] }
        return membersByGroupId[groupId] ?? []
    }

    func load(using service: MoilAPIService) async throws {
        isLoading = true
        defer { isLoading = false }
        groups = try await service.groups().map(MoilGroup.init(remote:))
        membersByGroupId = membersByGroupId.filter { groupID, _ in groups.contains { $0.id == groupID } }
        for (groupID, members) in membersByGroupId { applyMyColor(groupId: groupID, members: members) }
        if selectedGroupId == nil || !groups.contains(where: { $0.id == selectedGroupId }) {
            selectedGroupId = groups.first?.id
        }
        if let selectedGroupId {
            _ = try? await loadMembers(groupId: selectedGroupId, using: service)
        }
    }

    func create(name: String, nickname: String, colorId: String, using service: MoilAPIService) async throws {
        let group = try await service.createGroup(name: name, nickname: nickname, colorId: colorId)
        let localGroup = MoilGroup(remote: group)
        groups.append(localGroup)
        selectedGroupId = localGroup.id
        _ = try? await loadMembers(groupId: localGroup.id, using: service)
    }

    func join(inviteCode: String, nickname: String, colorId: String, using service: MoilAPIService) async throws {
        let group = try await service.joinGroup(inviteCode: inviteCode, nickname: nickname, colorId: colorId)
        let localGroup = MoilGroup(remote: group)
        // 참여 요청은 성공했는데 직후 목록 새로고침만 실패할 수 있습니다.
        // 그 경우에도 방금 받은 그룹을 즉시 화면 상태에 반영해야 빈 캘린더에 머물지 않습니다.
        try? await load(using: service)
        if !groups.contains(where: { $0.id == localGroup.id }) { groups.append(localGroup) }
        selectedGroupId = localGroup.id
        _ = try? await loadMembers(groupId: localGroup.id, using: service)
        pendingInviteCode = nil
        pendingInviteGroupName = ""
        pendingInviteMemberCount = 0
    }

    func selectGroup(_ id: String) {
        guard groups.contains(where: { $0.id == id }) else { return }
        selectedGroupId = id
    }

    func refreshDetail(id: String, using service: MoilAPIService) async throws {
        let remoteGroup = try await service.groupDetail(groupId: id)
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[index] = MoilGroup(remote: remoteGroup)
        if let members = remoteGroup.members {
            membersByGroupId[id] = members
            applyMyColor(groupId: id, members: members)
        }
    }

    func loadMembers(groupId: String, using service: MoilAPIService) async throws -> [MoilRemoteMember] {
        let members = try await service.members(groupId: groupId)
        membersByGroupId[groupId] = members
        applyMyColor(groupId: groupId, members: members)
        return members
    }

    /// 그룹 응답에 색상이 없으면 그 그룹에서 내가 고른 색을 그룹 색으로 씁니다.
    private func applyMyColor(groupId: String, members: [MoilRemoteMember]) {
        guard let index = groups.firstIndex(where: { $0.id == groupId }),
              groups[index].colorId?.isEmpty ?? true,
              let myColorId = members.first(where: \.isMe)?.colorId else { return }
        groups[index].colorId = myColorId
    }

    func renameGroup(id: String, name: String, using service: MoilAPIService) async throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        try await service.renameGroup(groupId: id, name: trimmedName)
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[index].name = trimmedName
    }

    func removeGroup(_ id: String) {
        groups.removeAll { $0.id == id }
        membersByGroupId[id] = nil
        if selectedGroupId == id {
            selectedGroupId = groups.first?.id
        }
    }

    func reset() {
        groups = []
        selectedGroupId = nil
        pendingInviteCode = nil
        pendingInviteGroupName = ""
        pendingInviteMemberCount = 0
        membersByGroupId = [:]
    }

}

extension MoilAvatarColor {
    static func color(for id: String?) -> Color {
        switch id?.uppercased() {
        case "SKY", "BLUE": blue
        case "RED": red
        case "GREEN": green
        case "YELLOW": yellow
        case "TEAL": green
        case "VIOLET", "PURPLE": purple
        case "MAGENTA", "PINK": pink
        case "ORANGE": orange
        default: green
        }
    }

    static func id(for color: Color) -> String {
        if color == blue { return "SKY" }
        if color == red { return "RED" }
        if color == yellow { return "YELLOW" }
        if color == purple { return "VIOLET" }
        if color == pink { return "MAGENTA" }
        if color == orange { return "ORANGE" }
        return "GREEN"
    }
}
