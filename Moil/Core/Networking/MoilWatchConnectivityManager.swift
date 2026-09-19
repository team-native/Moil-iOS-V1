import Foundation
import WatchConnectivity

/// 아이폰의 로그인 세션과 선택된 그룹을 애플워치 앱으로 넘겨줍니다.
/// 워치는 로그인 화면이 없으므로, 페어링된 아이폰이 이미 로그인돼 있으면
/// 그 세션을 그대로 물려받아 자체적으로 서버에 접속합니다.
@MainActor
final class MoilWatchConnectivityManager: NSObject {
    static let shared = MoilWatchConnectivityManager()

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sync(accessToken: String?, refreshToken: String?, groupId: String?) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        var context: [String: Any] = [:]
        context["accessToken"] = accessToken
        context["refreshToken"] = refreshToken
        context["groupId"] = groupId
        try? WCSession.default.updateApplicationContext(context)
    }
}

extension MoilWatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) { }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) { }
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
