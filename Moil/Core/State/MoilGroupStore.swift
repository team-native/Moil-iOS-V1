import SwiftUI
import Combine

struct MoilGroup: Identifiable {
    let id: String
    var name: String
    var colorId: String?
    var inviteCode: String?

    var color: Color { MoilAvatarColor.color(for: colorId) }

    init(id: String, name: String, colorId: String? = nil, inviteCode: String? = nil) {
        self.id = id
        self.name = name
        self.colorId = colorId
        self.inviteCode = inviteCode
    }

    init(remote: MoilRemoteGroup) {
        self.init(id: remote.id, name: remote.name, colorId: remote.colorId, inviteCode: remote.inviteCode)
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
        if selectedGroupId == nil || !groups.contains(where: { $0.id == selectedGroupId }) {
            selectedGroupId = groups.first?.id
        }
    }

    func create(name: String, nickname: String, colorId: String, using service: MoilAPIService) async throws {
        let group = try await service.createGroup(name: name, nickname: nickname, colorId: colorId)
        let localGroup = MoilGroup(remote: group)
        groups.append(localGroup)
        selectedGroupId = localGroup.id
    }

    func join(inviteCode: String, nickname: String, colorId: String, using service: MoilAPIService) async throws {
        let group = try await service.joinGroup(inviteCode: inviteCode, nickname: nickname, colorId: colorId)
        let localGroup = MoilGroup(remote: group)
        try await load(using: service)
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
    }

    func loadMembers(groupId: String, using service: MoilAPIService) async throws -> [MoilRemoteMember] {
        let members = try await service.members(groupId: groupId)
        membersByGroupId[groupId] = members
        return members
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
        if color == orange { return "YELLOW" }
        return "GREEN"
    }
}
