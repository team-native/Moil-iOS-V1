import Foundation

/// Moil-iOS-V1의 MoilAPIService를 워치에서 실제로 쓰는 읽기 전용 엔드포인트만 남겨 옮긴 버전입니다.
/// 워치는 자체 로그인 화면이 없으므로 로그인/회원가입 관련 엔드포인트는 옮기지 않았습니다.
struct MoilWatchAPIService {
    private let client: MoilAPIClient

    init(
        tokenProvider: @escaping () -> String? = { nil },
        tokenRefresher: (() async -> Bool)? = nil
    ) {
        client = MoilAPIClient(tokenProvider: tokenProvider, tokenRefresher: tokenRefresher)
    }

    func refreshToken(_ refreshToken: String) async throws -> MoilTokenResponse {
        try await client.request(
            "auth/refresh",
            method: "POST",
            body: RefreshTokenRequest(refreshToken: refreshToken),
            requiresAuthentication: false
        )
    }

    func groups() async throws -> [MoilRemoteGroup] {
        let response: MoilGroupList = try await client.request("groups/me", method: "POST")
        return response.groups
    }

    func members(groupId: String) async throws -> [MoilRemoteMember] {
        let response: MoilMemberList = try await client.request("groups/\(groupId)/members", method: "GET")
        return response.members
    }

    func events(groupId: String, month: String) async throws -> [MoilRemoteEvent] {
        let response: MoilEventList = try await client.request("groups/\(groupId)/events", method: "GET", queryItems: [URLQueryItem(name: "month", value: month)])
        return response.events
    }
}

private struct RefreshTokenRequest: Encodable {
    let refreshToken: String

    private enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
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

struct MoilRemoteGroup: Decodable, Identifiable {
    let id: String
    let name: String
    let colorId: String?
    let memberCount: Int?

    private enum CodingKeys: String, CodingKey { case id, groupId, name, groupName, colorId, myColor, memberCount }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.string(for: [.id, .groupId])
        name = try container.string(for: [.name, .groupName])
        colorId = (try? container.decode(String.self, forKey: .colorId))
            ?? (try? container.decode(String.self, forKey: .myColor))
        memberCount = try? container.decode(Int.self, forKey: .memberCount)
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
    let colorId: String?
    let isMe: Bool

    private enum CodingKeys: String, CodingKey {
        case id, userId, memberId, nickname, name, userName, colorId, profileColor, isMe
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.string(for: [.id, .userId, .memberId])
        nickname = (try? container.string(for: [.nickname, .name, .userName])) ?? "나"
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
    let members: [MoilEventMember]

    private enum CodingKeys: String, CodingKey {
        case id, eventId, title, date, startDate, endDate, ownerName, nickname, colorId, profileColor, members, sharedMembers, isAllDay, startTime, endTime, location
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.string(for: [.id, .eventId])
        title = try container.decode(String.self, forKey: .title)
        if let startDate = try? container.decode(String.self, forKey: .startDate) {
            date = Self.dateOnly(from: startDate)
        } else {
            date = Self.dateOnly(from: try container.decode(String.self, forKey: .date))
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
    }

    private static func time(from dateTime: String?) -> String? {
        guard let dateTime else { return nil }
        let components = dateTime.split(separator: " ", maxSplits: 1)
        guard components.count == 2 else { return nil }
        return String(components[1].prefix(5))
    }

    /// 서버가 `yyyy-MM-dd` 대신 `yyyy-MM-dd HH:mm:ss` 같은 전체 날짜시간 문자열을
    /// 줄 때가 있어, 이후 코드가 항상 순수 날짜 문자열만 다루도록 앞 10글자로 자릅니다.
    /// (아이폰 앱의 MoilCalendarDate.normalizedString과 같은 이유의 처리입니다.)
    private static func dateOnly(from value: String) -> String {
        String(value.prefix(10))
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

private extension KeyedDecodingContainer {
    func string(for keys: [Key]) throws -> String {
        for key in keys {
            if let string = try? decode(String.self, forKey: key) { return string }
            if let integer = try? decode(Int.self, forKey: key) { return String(integer) }
        }
        throw MoilAPIError.decoding
    }
}
