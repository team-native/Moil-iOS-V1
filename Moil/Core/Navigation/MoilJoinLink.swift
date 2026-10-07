import Foundation

/// 그룹 초대 링크. 서버 `GET /join/{groupId}`가 `moil://join/{groupId}`로 리다이렉트합니다.
/// 링크에 초대 코드(`?code=`)가 실려 오면 참여 화면에서 바로 확인까지 진행합니다.
struct MoilJoinLink: Equatable {
    let groupId: String?
    let inviteCode: String?

    init?(url: URL) {
        guard url.scheme?.lowercased() == "moil", url.host?.lowercased() == "join" else { return nil }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let query = components?.queryItems ?? []
        func value(_ name: String) -> String? {
            query.first { $0.name == name }?.value?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        }
        groupId = url.pathComponents.first { $0 != "/" }?.nilIfEmpty ?? value("groupId")
        inviteCode = (value("code") ?? value("inviteCode"))?.uppercased()
        guard groupId != nil || inviteCode != nil else { return nil }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
