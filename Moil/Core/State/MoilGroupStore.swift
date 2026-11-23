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
    /// 초대 링크로 앱이 열렸을 때 메인 화면에서 처리할 링크. 로그인 전이면 로그인 후까지 유지됩니다.
    @Published var pendingJoinLink: MoilJoinLink?
    /// 푸시 알림을 탭해 열렸을 때 메인 화면에서 전환할 그룹
    @Published var pendingNotificationGroupId: String?
    /// 일정 알림을 탭해 열렸을 때 캘린더에서 상세를 띄울 일정
    @Published var pendingNotificationEventId: String?
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
    static let rgbById: [String: (red: Int, green: Int, blue: Int)] = [
        "RED": (244, 67, 54),
        "ORANGE": (255, 152, 0),
        "YELLOW": (255, 235, 59),
        "GREEN": (76, 175, 80),
        "BLUE": (33, 150, 243),
        "NAVY": (25, 55, 109),
        "INDIGO": (63, 81, 181),
        "PURPLE": (156, 39, 176),
        "PINK": (233, 30, 99),
        "CREAM": (255, 248, 225),
        "PEACH": (255, 204, 188),
        "APRICOT": (255, 183, 77),
        "TAN": (188, 143, 107),
        "GOLD": (255, 193, 7),
        "CORAL": (255, 111, 97),
        "ROSE": (233, 90, 119),
        "SKY": (3, 169, 244),
        "LIGHT_BLUE": (129, 212, 250),
        "MINT": (128, 203, 196),
        "TEAL": (0, 150, 136),
        "LIGHT_GREEN": (139, 195, 74),
        "VIVID_GREEN": (0, 200, 83),
        "VIOLET": (103, 58, 183),
        "MAGENTA": (216, 27, 96),
        "VIVID_ORANGE": (255, 87, 34),
        "VIVID_RED": (213, 0, 0),
        "WARM_PINK": (255, 64, 129),
    ]

    static func color(for id: String?) -> Color {
        guard let id, let rgb = rgbById[id.uppercased()] else { return green }
        return Color(red: Double(rgb.red) / 255, green: Double(rgb.green) / 255, blue: Double(rgb.blue) / 255)
    }

    /// 서버(`MoilColor.nearest`)와 같은 방식으로 가장 가까운 팔레트 색을 찾습니다.
    static func nearestId(red: Int, green: Int, blue: Int) -> String {
        rgbById.min { lhs, rhs in
            distance(lhs.value, red, green, blue) < distance(rhs.value, red, green, blue)
        }?.key ?? "RED"
    }

    private static func distance(_ rgb: (red: Int, green: Int, blue: Int), _ red: Int, _ green: Int, _ blue: Int) -> Int {
        let r = red - rgb.red, g = green - rgb.green, b = blue - rgb.blue
        return r * r + g * g + b * b
    }

    /// 프로필 색 선택 화면에 보여줄 스와치입니다. 서버 팔레트 중 아바타의 흰 눈·입이 보이고
    /// 라이트(Surface)·다크(검정) 배경 모두에서 대비가 2.5:1 이상인 색만 골라 색상환 순서로 둡니다.
    /// 너무 밝은 색(CREAM, YELLOW 등)과 다크 모드에서 묻히는 NAVY는 사진 자동 추출로만 쓰입니다.
    static let selectableIds = [
        "RED", "VIVID_ORANGE", "TAN", "GREEN", "TEAL", "BLUE",
        "INDIGO", "VIOLET", "PURPLE", "MAGENTA", "ROSE",
    ]

    /// VoiceOver에서 스와치를 구분할 수 있도록 서버(`MoilColor.kt`)의 displayName을 그대로 씁니다.
    private static let nameById: [String: String] = [
        "RED": "빨간색", "ORANGE": "주황색", "YELLOW": "노란색", "GREEN": "초록색", "BLUE": "파란색",
        "NAVY": "남색", "INDIGO": "남색", "PURPLE": "보라색", "PINK": "핑크색", "CREAM": "크림색",
        "PEACH": "피치색", "APRICOT": "살구색", "TAN": "탄색", "GOLD": "금색", "CORAL": "코랄색",
        "ROSE": "장미색", "SKY": "하늘색", "LIGHT_BLUE": "연파랑색", "MINT": "민트색", "TEAL": "청록색",
        "LIGHT_GREEN": "연초록색", "VIVID_GREEN": "선명한 초록색", "VIOLET": "보라색", "MAGENTA": "자주색",
        "VIVID_ORANGE": "선명한 주황색", "VIVID_RED": "선명한 빨간색", "WARM_PINK": "웜 핑크색",
    ]

    static func name(for id: String) -> String {
        nameById[id.uppercased()] ?? "프로필 색"
    }
}
