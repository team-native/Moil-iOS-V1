import Foundation

struct MoilAPIService {
    private let client: MoilAPIClient

    init(tokenProvider: @escaping () -> String? = { nil }) {
        client = MoilAPIClient(tokenProvider: tokenProvider)
    }

    func login(email: String, password: String) async throws -> MoilTokenResponse {
        try await client.request("auth/login", method: "POST", body: LoginRequest(email: email, password: password), requiresAuthentication: false)
    }

    func refreshToken(_ refreshToken: String) async throws -> MoilTokenResponse {
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        do {
            // 최신 명세의 Bearer 인증 방식을 우선 적용합니다.
            return try await client.request("auth/refresh", method: "POST", body: request)
        } catch let error as MoilAPIError where error.isAuthenticationFailure {
            // 액세스 토큰이 이미 만료된 환경에서도 리프레시 토큰만으로 재발급을
            // 허용하는 서버와 호환하기 위한 보조 경로입니다.
            return try await client.request(
                "auth/refresh",
                method: "POST",
                body: request,
                requiresAuthentication: false
            )
        }
    }

    func sendVerificationCode(name: String?, email: String, step: VerificationStep) async throws -> MoilVerificationResponse {
        try await client.request("auth/send-code", method: "POST", body: SendCodeRequest(name: name, email: email, step: step), requiresAuthentication: false)
    }

    func verifyCode(verifyId: String, code: String) async throws -> MoilVerificationSession {
        try await client.request("auth/verify-code", method: "POST", body: VerifyCodeRequest(verifyId: verifyId, code: code), requiresAuthentication: false)
    }

    func confirmSignUp(sessionId: String, password: String, confirmation: String) async throws -> MoilTokenResponse {
        try await client.request("auth/confirm", method: "POST", body: PasswordConfirmationRequest(sessionId: sessionId, password: password, pwd: confirmation), requiresAuthentication: false)
    }

    func resetPassword(sessionId: String, password: String, confirmation: String) async throws -> MoilTokenResponse {
        try await client.request("auth/reset-password", method: "POST", body: PasswordConfirmationRequest(sessionId: sessionId, password: password, pwd: confirmation), requiresAuthentication: false)
    }

    func changePassword(origin: String, newPassword: String, confirmation: String) async throws {
        try await client.request("auth/change-password", method: "POST", body: ChangePasswordRequest(origin: origin, newpwd: newPassword, checkpwd: confirmation))
    }

    func deleteAccount(email: String, password: String, leftData: Bool) async throws {
        try await client.request("auth/delete-account", method: "POST", body: DeleteAccountRequest(email: email, password: password, leftData: leftData))
    }

    func logout() async throws {
        try await client.request("auth/logout", method: "POST", body: EmptyRequest())
    }

    func groups() async throws -> [MoilRemoteGroup] {
        let response: MoilGroupList = try await client.request("groups/me", method: "POST", body: EmptyRequest())
        return response.groups
    }

    func createGroup(name: String, nickname: String, colorId: String) async throws -> MoilRemoteGroup {
        try await client.request("groups", method: "POST", body: CreateGroupRequest(name: name, nickname: nickname, colorId: colorId))
    }

    func verifyInviteCode(_ inviteCode: String) async throws -> MoilInviteVerification {
        try await client.request("groups/join/verify", method: "POST", body: InviteCodeRequest(inviteCode: inviteCode))
    }

    func joinGroup(inviteCode: String, nickname: String, colorId: String) async throws -> MoilRemoteGroup {
        try await client.request("groups/join", method: "POST", body: JoinGroupRequest(inviteCode: inviteCode, nickname: nickname, colorId: colorId))
    }

    func groupDetail(groupId: String) async throws -> MoilRemoteGroup {
        try await client.request("groups/\(groupId)", method: "GET")
    }

    func members(groupId: String) async throws -> [MoilRemoteMember] {
        let response: MoilMemberList = try await client.request("groups/\(groupId)/members", method: "GET")
        return response.members
    }

    func setNotification(groupId: String, enabled: Bool) async throws {
        try await client.request("groups/\(groupId)/notification", method: "PATCH", body: NotificationRequest(enabled: enabled))
    }

    func leaveGroup(groupId: String) async throws {
        try await client.request("groups/\(groupId)/members/me", method: "DELETE", body: EmptyRequest())
    }

    func renameGroup(groupId: String, name: String) async throws {
        try await client.request("groups/\(groupId)", method: "PATCH", body: RenameGroupRequest(name: name))
    }

    func transferAdmin(groupId: String, targetUserId: Int) async throws {
        try await client.request("groups/\(groupId)/transfer-admin", method: "POST", body: TransferAdminRequest(targetUserId: targetUserId))
    }

    func updateMemberRoles(groupId: String, members: [MemberRoleRequest]) async throws {
        try await client.request("groups/\(groupId)/members", method: "PATCH", body: MemberRoleUpdateRequest(members: members))
    }

    func events(groupId: String, month: Int) async throws -> [MoilRemoteEvent] {
        let response: MoilEventList = try await client.request("groups/\(groupId)/events", method: "GET", queryItems: [URLQueryItem(name: "month", value: String(month))])
        return response.events
    }

    func createEvent(_ request: CreateEventRequest) async throws -> String {
        let response: MoilCreatedEvent = try await client.request("events", method: "POST", body: request)
        return response.eventId
    }

    func event(id: String) async throws -> MoilRemoteEvent {
        try await client.request("events/\(id)", method: "GET")
    }

    func updateEvent(id: String, request: UpdateEventRequest) async throws {
        try await client.request("events/\(id)", method: "PATCH", body: request)
    }

    func deleteEvent(id: String) async throws {
        try await client.request("events/\(id)", method: "DELETE", body: EmptyRequest())
    }
}

enum VerificationStep: String, Codable { case signUp = "SIGNUP", reset = "RESET" }

private struct EmptyRequest: Encodable { }
private struct LoginRequest: Encodable { let email: String; let password: String }
private struct RefreshTokenRequest: Encodable {
    let refreshToken: String

    private enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}
private struct SendCodeRequest: Encodable { let name: String?; let email: String; let step: VerificationStep }
private struct VerifyCodeRequest: Encodable { let verifyId: String; let code: String }
private struct PasswordConfirmationRequest: Encodable { let sessionId: String; let password: String; let pwd: String }
private struct ChangePasswordRequest: Encodable { let origin: String; let newpwd: String; let checkpwd: String }
private struct DeleteAccountRequest: Encodable { let email: String; let password: String; let leftData: Bool }
private struct CreateGroupRequest: Encodable { let name: String; let nickname: String; let colorId: String }
private struct InviteCodeRequest: Encodable { let inviteCode: String }
private struct JoinGroupRequest: Encodable { let inviteCode: String; let nickname: String; let colorId: String }
private struct NotificationRequest: Encodable { let enabled: Bool }
private struct RenameGroupRequest: Encodable { let name: String }
private struct TransferAdminRequest: Encodable { let targetUserId: Int }
private struct MemberRoleUpdateRequest: Encodable { let members: [MemberRoleRequest] }

struct MemberRoleRequest: Encodable {
    let userId: Int
    let role: String
}

struct MoilTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?

    private enum CodingKeys: String, CodingKey {
        case accessToken, refreshToken
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
    }
}

struct MoilVerificationResponse: Decodable {
    let verifyId: String
}

struct MoilVerificationSession: Decodable {
    let sessionId: String
}

struct MoilInviteVerification: Decodable {
    let groupId: String
    let groupName: String
    let memberCount: Int
    let inviteCode: String

    private enum CodingKeys: String, CodingKey { case groupId, id, groupName, name, memberCount, inviteCode }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        groupId = try container.string(for: [.groupId, .id])
        if let legacyGroupName = try? container.decode(String.self, forKey: .groupName) {
            groupName = legacyGroupName
        } else {
            groupName = try container.decode(String.self, forKey: .name)
        }
        memberCount = (try? container.decode(Int.self, forKey: .memberCount)) ?? 0
        inviteCode = try container.decode(String.self, forKey: .inviteCode)
    }
}

struct MoilRemoteGroup: Decodable, Identifiable {
    let id: String
    let name: String
    let colorId: String?
    let inviteCode: String?

    private enum CodingKeys: String, CodingKey { case id, groupId, name, groupName, colorId, myColor, inviteCode }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.string(for: [.id, .groupId])
        name = try container.string(for: [.name, .groupName])
        colorId = (try? container.decode(String.self, forKey: .colorId))
            ?? (try? container.decode(String.self, forKey: .myColor))
        inviteCode = try? container.decode(String.self, forKey: .inviteCode)
    }
}

private struct MoilGroupList: Decodable {
    let groups: [MoilRemoteGroup]
    init(from decoder: Decoder) throws {
        if var list = try? decoder.unkeyedContainer() {
            var result: [MoilRemoteGroup] = []
            while !list.isAtEnd { result.append(try list.decode(MoilRemoteGroup.self)) }
            groups = result
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decoded = try? container.decode([MoilRemoteGroup].self, forKey: .groups) {
            groups = decoded
        } else {
            groups = try container.decode([MoilRemoteGroup].self, forKey: .items)
        }
    }
    private enum CodingKeys: String, CodingKey { case groups, items }
}

struct MoilRemoteMember: Decodable, Identifiable {
    let id: String
    let nickname: String
    let role: String
    let colorId: String?
    let isMe: Bool

    private enum CodingKeys: String, CodingKey {
        case id, userId, memberId, nickname, name, userName, role, groupRole, colorId, profileColor, isMe
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.string(for: [.id, .userId, .memberId])
        nickname = (try? container.string(for: [.nickname, .name, .userName])) ?? "나"
        role = (try? container.string(for: [.role, .groupRole])) ?? "MEMBER"
        colorId = try? container.string(for: [.colorId, .profileColor])
        isMe = (try? container.decode(Bool.self, forKey: .isMe)) ?? false
    }
}

private struct MoilMemberList: Decodable {
    let members: [MoilRemoteMember]
    init(from decoder: Decoder) throws {
        if var list = try? decoder.unkeyedContainer() {
            var result: [MoilRemoteMember] = []
            while !list.isAtEnd { result.append(try list.decode(MoilRemoteMember.self)) }
            members = result
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decoded = try? container.decode([MoilRemoteMember].self, forKey: .members) {
            members = decoded
        } else {
            members = try container.decode([MoilRemoteMember].self, forKey: .items)
        }
    }
    private enum CodingKeys: String, CodingKey { case members, items }
}

struct MoilRemoteEvent: Decodable, Identifiable {
    let id: String
    let title: String
    let date: String
    let ownerName: String?
    let colorId: String?
    let isAllDay: Bool
    let startTime: String?
    let endTime: String?
    let location: String?
    let members: [MoilEventMember]

    private enum CodingKeys: String, CodingKey {
        case id, eventId, title, date, ownerName, nickname, colorId, profileColor, members, sharedMembers, isAllDay, startTime, endTime, location
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.string(for: [.id, .eventId])
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(String.self, forKey: .date)

        members = (try? container.decode([MoilEventMember].self, forKey: .members))
            ?? (try? container.decode([MoilEventMember].self, forKey: .sharedMembers))
            ?? []
        ownerName = (try? container.decode(String.self, forKey: .ownerName))
            ?? (try? container.decode(String.self, forKey: .nickname))
            ?? members.first?.nickname
        colorId = (try? container.decode(String.self, forKey: .colorId))
            ?? (try? container.decode(String.self, forKey: .profileColor))
            ?? members.first?.colorId
        isAllDay = (try? container.decode(Bool.self, forKey: .isAllDay)) ?? true
        startTime = try? container.decode(String.self, forKey: .startTime)
        endTime = try? container.decode(String.self, forKey: .endTime)
        location = try? container.decode(String.self, forKey: .location)
    }
}

struct MoilEventMember: Decodable {
    let id: String?
    let nickname: String?
    let colorId: String?

    private enum CodingKeys: String, CodingKey { case id, userId, memberId, nickname, name, colorId, profileColor }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.string(for: [.id, .userId, .memberId]))
        nickname = (try? container.decode(String.self, forKey: .nickname))
            ?? (try? container.decode(String.self, forKey: .name))
        colorId = (try? container.decode(String.self, forKey: .colorId))
            ?? (try? container.decode(String.self, forKey: .profileColor))
    }
}

private struct MoilEventList: Decodable {
    let events: [MoilRemoteEvent]
    init(from decoder: Decoder) throws {
        if var list = try? decoder.unkeyedContainer() {
            var result: [MoilRemoteEvent] = []
            while !list.isAtEnd { result.append(try list.decode(MoilRemoteEvent.self)) }
            events = result
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decoded = try? container.decode([MoilRemoteEvent].self, forKey: .events) {
            events = decoded
        } else {
            events = try container.decode([MoilRemoteEvent].self, forKey: .items)
        }
    }
    private enum CodingKeys: String, CodingKey { case events, items }
}

struct CreateEventRequest: Encodable {
    let groupId: Int
    let title: String
    let date: String
    let isAllDay: Bool
    let startTime: String?
    let endTime: String?
    let location: String?
    let sharedMemberIds: [Int]
}

struct UpdateEventRequest: Encodable {
    let title: String
    let date: String
    let isAllDay: Bool
    let startTime: String?
    let endTime: String?
    let location: String?
    let sharedMemberIds: [Int]
}

private struct MoilCreatedEvent: Decodable {
    let eventId: String

    private enum CodingKeys: String, CodingKey { case eventId, id }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventId = try container.string(for: [.eventId, .id])
    }
}

private extension KeyedDecodingContainer {
    func string(for keys: [Key]) throws -> String {
        for key in keys {
            if let string = try? decode(String.self, forKey: key) { return string }
            if let integer = try? decode(Int.self, forKey: key) { return String(integer) }
        }
        throw MoilAPIError.decoding
    }
}
