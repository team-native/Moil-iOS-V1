import Foundation
import UIKit

/// 서버(`ImageService`)는 파일 시그니처로 PNG/JPEG/WEBP만 허용하고 2MB를 넘으면 거부합니다.
/// 아이폰 사진은 기본이 HEIC라서, `PhotosPicker`가 준 원본 데이터를 그대로 올리면 형식 거부로
/// 실패할 수 있습니다. 항상 JPEG로 다시 인코딩하고, 필요하면 화질을 낮춰 용량 제한 안에 맞춥니다.
enum MoilProfileImageEncoder {
    static let maxUploadBytes = 2 * 1024 * 1024

    static func jpegData(from image: UIImage) -> Data? {
        for quality in [0.85, 0.6, 0.4, 0.25] {
            if let data = image.jpegData(compressionQuality: quality), data.count <= maxUploadBytes {
                return data
            }
        }
        return image.jpegData(compressionQuality: 0.1)
    }
}

struct MoilAPIService {
    private let client: MoilAPIClient

    init(
        tokenProvider: @escaping () -> String? = { nil },
        tokenRefresher: (() async -> Bool)? = nil
    ) {
        client = MoilAPIClient(tokenProvider: tokenProvider, tokenRefresher: tokenRefresher)
    }

    func login(email: String, password: String) async throws -> MoilTokenResponse {
        try await client.request("auth/login", method: "POST", body: LoginRequest(email: email, password: password), requiresAuthentication: false)
    }

    func refreshToken(_ refreshToken: String) async throws -> MoilTokenResponse {
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        // 만료된 access token을 실어 보내면 재발급 자체가 실패할 수 있으므로,
        // 명세의 refresh_token body만 사용합니다.
        return try await client.request(
            "auth/refresh",
            method: "POST",
            body: request,
            requiresAuthentication: false
        )
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

    func resetPassword(sessionId: String, password: String, confirmation: String) async throws {
        try await client.request("auth/reset-password", method: "POST", body: PasswordConfirmationRequest(sessionId: sessionId, password: password, pwd: confirmation), requiresAuthentication: false)
    }

    func changePassword(origin: String, newPassword: String, confirmation: String) async throws {
        try await client.request("auth/change-password", method: "POST", body: ChangePasswordRequest(origin: origin, newpwd: newPassword, checkpwd: confirmation))
    }

    func deleteAccount(email: String, password: String, leftData: Bool) async throws {
        try await client.request("auth/delete-account", method: "POST", body: DeleteAccountRequest(email: email, password: password, leftData: leftData))
    }

    func logout() async throws {
        let _: MoilEmptyResponse = try await client.request("auth/logout", method: "POST")
    }

    func groups() async throws -> [MoilRemoteGroup] {
        let response: MoilGroupList = try await client.request("groups/me", method: "POST")
        return response.groups
    }

    func createGroup(name: String, nickname: String, colorId: String?, imagePath: String? = nil) async throws -> MoilRemoteGroup {
        try await client.request("groups", method: "POST", body: CreateGroupRequest(name: name, nickname: nickname, colorId: colorId, imagePath: imagePath))
    }

    func verifyInviteCode(_ inviteCode: String) async throws -> MoilInviteVerification {
        try await client.request("groups/join/verify", method: "POST", body: InviteCodeRequest(inviteCode: inviteCode))
    }

    func joinGroup(inviteCode: String, nickname: String, colorId: String?, imagePath: String? = nil) async throws -> MoilRemoteGroup {
        try await client.request("groups/join", method: "POST", body: JoinGroupRequest(inviteCode: inviteCode, nickname: nickname, colorId: colorId, imagePath: imagePath))
    }

    /// 프로필 이미지를 업로드하고, 그룹 생성/참여 요청에 실어 보낼 `imagePath`를 반환합니다.
    /// 서버는 `colorId`를 함께 보내지 않으면 이 이미지에서 대표 색상을 자동으로 추출합니다.
    func uploadProfileImage(data: Data, filename: String, mimeType: String) async throws -> String {
        let response: MoilImageUploadResponse = try await client.upload(
            "images",
            fieldName: "image",
            filename: filename,
            mimeType: mimeType,
            data: data
        )
        return response.imagePath
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
        let _: MoilEmptyResponse = try await client.request("groups/\(groupId)/members/me", method: "DELETE")
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

    func events(groupId: String, month: String) async throws -> [MoilRemoteEvent] {
        let response: MoilEventList = try await client.request("groups/\(groupId)/events", method: "GET", queryItems: [URLQueryItem(name: "month", value: month)])
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
        let _: MoilEmptyResponse = try await client.request("events/\(id)", method: "DELETE")
    }
}

enum VerificationStep: String, Codable { case signUp = "SIGNUP", reset = "RESET" }

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
private struct CreateGroupRequest: Encodable { let name: String; let nickname: String; let colorId: String?; let imagePath: String? }
private struct InviteCodeRequest: Encodable { let inviteCode: String }
private struct JoinGroupRequest: Encodable { let inviteCode: String; let nickname: String; let colorId: String?; let imagePath: String? }
private struct MoilImageUploadResponse: Decodable { let imagePath: String }
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

    init(accessToken: String, refreshToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
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
    let memberCount: Int?
    let myRole: String?
    let members: [MoilRemoteMember]?

    private enum CodingKeys: String, CodingKey { case id, groupId, name, groupName, colorId, myColor, inviteCode, memberCount, myRole, members }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.string(for: [.id, .groupId])
        name = try container.string(for: [.name, .groupName])
        colorId = (try? container.decode(String.self, forKey: .colorId))
            ?? (try? container.decode(String.self, forKey: .myColor))
        inviteCode = try? container.decode(String.self, forKey: .inviteCode)
        memberCount = try? container.decode(Int.self, forKey: .memberCount)
        myRole = try? container.decode(String.self, forKey: .myRole)
        members = try? container.decode([MoilRemoteMember].self, forKey: .members)
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
    let endDate: String?
    let ownerName: String?
    let colorId: String?
    let isAllDay: Bool
    let startTime: String?
    let endTime: String?
    let location: String?
    let memo: String?
    let members: [MoilEventMember]

    private enum CodingKeys: String, CodingKey {
        case id, eventId, title, date, startDate, endDate, ownerName, nickname, colorId, profileColor, members, sharedMembers, isAllDay, startTime, endTime, location, memo, description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.string(for: [.id, .eventId])
        title = try container.decode(String.self, forKey: .title)
        if let startDate = try? container.decode(String.self, forKey: .startDate) {
            date = startDate
        } else {
            date = try container.decode(String.self, forKey: .date)
        }
        endDate = try? container.decode(String.self, forKey: .endDate)

        members = (try? container.decode([MoilEventMember].self, forKey: .members))
            ?? (try? container.decode([MoilEventMember].self, forKey: .sharedMembers))
            ?? []
        ownerName = (try? container.decode(String.self, forKey: .ownerName))
            ?? (try? container.decode(String.self, forKey: .nickname))
            ?? members.first?.nickname
        colorId = (try? container.decode(String.self, forKey: .colorId))
            ?? (try? container.decode(String.self, forKey: .profileColor))
            ?? members.first?.colorId
        let serverStartDate = try? container.decode(String.self, forKey: .startDate)
        let serverEndDate = try? container.decode(String.self, forKey: .endDate)
        startTime = (try? container.decode(String.self, forKey: .startTime))
            ?? Self.time(from: serverStartDate)
        endTime = (try? container.decode(String.self, forKey: .endTime))
            ?? Self.time(from: serverEndDate)
        isAllDay = (try? container.decode(Bool.self, forKey: .isAllDay))
            ?? (startTime == "00:00" && endTime == "00:00")
        location = try? container.decode(String.self, forKey: .location)
        memo = (try? container.decode(String.self, forKey: .memo))
            ?? (try? container.decode(String.self, forKey: .description))
    }

    private static func time(from dateTime: String?) -> String? {
        guard let dateTime else { return nil }
        let components = dateTime.split(separator: " ", maxSplits: 1)
        guard components.count == 2 else { return nil }
        return String(components[1].prefix(5))
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
    let startDate: String
    let endDate: String
    let location: String?
    let memo: String?
    let sharedMemberIds: [Int]
}

struct UpdateEventRequest: Encodable {
    let title: String
    let startDate: String
    let endDate: String
    let location: String?
    let memo: String?
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
