import Foundation
import WatchConnectivity

/// 아이폰의 로그인 세션과 선택된 그룹을 애플워치 앱으로 넘겨줍니다.
/// 워치는 로그인 화면이 없으므로, 페어링된 아이폰이 이미 로그인돼 있으면
/// 그 세션을 그대로 물려받아 자체적으로 서버에 접속합니다.
@MainActor
final class MoilWatchConnectivityManager: NSObject {
    static let shared = MoilWatchConnectivityManager()
    /// WCSession.activate()는 비동기라, activate() 직후 곧바로 sync를 호출하면
    /// 아직 .activated 상태가 아니어서 조용히 무시될 수 있습니다(특히 이미 로그인된 채로
    /// 앱을 다시 켠 경우, 그 이후로는 토큰이 바뀔 일이 없어 재시도 기회도 없었습니다).
    /// 활성화가 실제로 끝난 시점에 한 번 더 보내도록 콜백을 둡니다.
    var onActivated: (() -> Void)?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sync(accessToken: String?, refreshToken: String?, groupId: String?, isDarkMode: Bool) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        var context: [String: Any] = [:]
        context["accessToken"] = accessToken
        context["refreshToken"] = refreshToken
        context["groupId"] = groupId
        context["isDarkMode"] = isDarkMode
        try? WCSession.default.updateApplicationContext(context)
    }
}

extension MoilWatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        guard activationState == .activated else { return }
        Task { @MainActor in
            MoilWatchConnectivityManager.shared.onActivated?()
        }
    }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) { }
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
