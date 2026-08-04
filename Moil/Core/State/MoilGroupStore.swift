import SwiftUI
import Combine

struct MoilGroup: Identifiable {
    let id: String
    var name: String
    var colorId: String?

    var color: Color { MoilAvatarColor.color(for: colorId) }

    init(id: String, name: String, colorId: String? = nil) {
        self.id = id
        self.name = name
        self.colorId = colorId
    }

    init(remote: MoilRemoteGroup) {
        self.init(id: remote.id, name: remote.name, colorId: remote.colorId)
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

    var selectedGroup: MoilGroup? {
        groups.first { $0.id == selectedGroupId } ?? groups.first
    }

    var selectedGroupName: String { selectedGroup?.name ?? "그룹 선택" }

    func load(using service: MoilAPIService) async throws {
        isLoading = true
        defer { isLoading = false }
        groups = try await service.groups().map(MoilGroup.init(remote:))
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
        if !groups.contains(where: { $0.id == localGroup.id }) { groups.append(localGroup) }
        selectedGroupId = localGroup.id
    }

    func selectGroup(_ id: String) {
        guard groups.contains(where: { $0.id == id }) else { return }
        selectedGroupId = id
    }

    func reset() {
        groups = []
        selectedGroupId = nil
        pendingInviteCode = nil
        pendingInviteGroupName = ""
        pendingInviteMemberCount = 0
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
