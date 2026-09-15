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

    func create(name: String, nickname: String, colorId: String?, imagePath: String? = nil, using service: MoilAPIService) async throws {
        let group = try await service.createGroup(name: name, nickname: nickname, colorId: colorId, imagePath: imagePath)
        let localGroup = MoilGroup(remote: group)
        groups.append(localGroup)
        selectedGroupId = localGroup.id
        _ = try? await loadMembers(groupId: localGroup.id, using: service)
    }

    func join(inviteCode: String, nickname: String, colorId: String?, imagePath: String? = nil, using service: MoilAPIService) async throws {
        let group = try await service.joinGroup(inviteCode: inviteCode, nickname: nickname, colorId: colorId, imagePath: imagePath)
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

    func updateMyProfile(groupId: String, nickname: String, colorId: String?, imagePath: String? = nil, using service: MoilAPIService) async throws {
        _ = try await service.updateMyProfile(groupId: groupId, nickname: nickname, colorId: colorId, imagePath: imagePath)
        _ = try? await loadMembers(groupId: groupId, using: service)
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
    /// 서버(`MoilColor.kt`)가 정의한 전체 색상 팔레트입니다. RGB 값은 서버와 동일하게 맞춰,
    /// 사진에서 자동 추출된 색상(27종 전체)이 여기 8종짜리 스와치에 없어도 정확한 색으로 표시되도록 합니다.
    private static let paletteById: [String: Color] = [
        "RED": Color(red: 244 / 255, green: 67 / 255, blue: 54 / 255),
        "ORANGE": Color(red: 255 / 255, green: 152 / 255, blue: 0 / 255),
        "YELLOW": Color(red: 255 / 255, green: 235 / 255, blue: 59 / 255),
        "GREEN": Color(red: 76 / 255, green: 175 / 255, blue: 80 / 255),
        "BLUE": Color(red: 33 / 255, green: 150 / 255, blue: 243 / 255),
        "NAVY": Color(red: 25 / 255, green: 55 / 255, blue: 109 / 255),
        "INDIGO": Color(red: 63 / 255, green: 81 / 255, blue: 181 / 255),
        "PURPLE": Color(red: 156 / 255, green: 39 / 255, blue: 176 / 255),
        "PINK": Color(red: 233 / 255, green: 30 / 255, blue: 99 / 255),
        "CREAM": Color(red: 255 / 255, green: 248 / 255, blue: 225 / 255),
        "PEACH": Color(red: 255 / 255, green: 204 / 255, blue: 188 / 255),
        "APRICOT": Color(red: 255 / 255, green: 183 / 255, blue: 77 / 255),
        "TAN": Color(red: 188 / 255, green: 143 / 255, blue: 107 / 255),
        "GOLD": Color(red: 255 / 255, green: 193 / 255, blue: 7 / 255),
        "CORAL": Color(red: 255 / 255, green: 111 / 255, blue: 97 / 255),
        "ROSE": Color(red: 233 / 255, green: 90 / 255, blue: 119 / 255),
        "SKY": Color(red: 3 / 255, green: 169 / 255, blue: 244 / 255),
        "LIGHT_BLUE": Color(red: 129 / 255, green: 212 / 255, blue: 250 / 255),
        "MINT": Color(red: 128 / 255, green: 203 / 255, blue: 196 / 255),
        "TEAL": Color(red: 0 / 255, green: 150 / 255, blue: 136 / 255),
        "LIGHT_GREEN": Color(red: 139 / 255, green: 195 / 255, blue: 74 / 255),
        "VIVID_GREEN": Color(red: 0 / 255, green: 200 / 255, blue: 83 / 255),
        "VIOLET": Color(red: 103 / 255, green: 58 / 255, blue: 183 / 255),
        "MAGENTA": Color(red: 216 / 255, green: 27 / 255, blue: 96 / 255),
        "VIVID_ORANGE": Color(red: 255 / 255, green: 87 / 255, blue: 34 / 255),
        "VIVID_RED": Color(red: 213 / 255, green: 0 / 255, blue: 0 / 255),
        "WARM_PINK": Color(red: 255 / 255, green: 64 / 255, blue: 129 / 255),
    ]

    static func color(for id: String?) -> Color {
        guard let id, let color = paletteById[id.uppercased()] else { return green }
        return color
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
