import Foundation
import WatchConnectivity

/// 아이폰의 로그인 세션과 선택된 그룹을 애플워치 앱으로 넘겨줍니다.
/// 워치는 로그인 화면이 없으므로, 페어링된 아이폰이 이미 로그인돼 있으면
/// 그 세션을 그대로 물려받아 자체적으로 서버에 접속합니다.
///
/// 서버는 토큰을 재발급할 때 이전 세션을 지우므로, 아이폰과 워치 중 한쪽이 재발급하면
/// 다른 쪽 토큰은 바로 무효가 됩니다. 그래서 양쪽이 새 토큰을 서로 넘겨받습니다.
/// - 워치가 401을 받으면 먼저 아이폰에 최신 토큰을 요청합니다(`requestSession`).
/// - 아이폰이 닿지 않아 워치가 직접 재발급하면, 새 토큰을 applicationContext로 아이폰에 남깁니다.
@MainActor
final class MoilWatchConnectivityManager: NSObject {
    static let shared = MoilWatchConnectivityManager()
    /// WCSession.activate()는 비동기라, activate() 직후 곧바로 sync를 호출하면
    /// 아직 .activated 상태가 아니어서 조용히 무시될 수 있습니다.
    /// 활성화가 실제로 끝난 시점에 한 번 더 보내도록 콜백을 둡니다.
    var onActivated: (() -> Void)?
    /// 워치가 토큰을 요청하면 아이폰 세션을 확인(필요하면 재발급)한 뒤 최신 토큰을 돌려줍니다.
    var sessionProvider: (() async -> (accessToken: String?, refreshToken: String?))?
    /// 워치가 직접 재발급한 토큰을 받았을 때 아이폰 세션에 반영합니다.
    var onTokensFromWatch: ((MoilWatchTokens) -> Void)?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// 워치가 직접 재발급해 남겨 둔 토큰입니다. 아이폰 재발급이 실패했을 때 이 값으로 세션을 이어갑니다.
    func latestTokensFromWatch() -> MoilWatchTokens? {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return nil }
        return MoilWatchTokens(context: WCSession.default.receivedApplicationContext)
    }

    func sync(accessToken: String?, refreshToken: String?, groupId: String?, isDarkMode: Bool) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else {
#if DEBUG
            print("[MoilWatchSync] 전송 건너뜀 - supported: \(WCSession.isSupported()), activationState: \(WCSession.isSupported() ? "\(WCSession.default.activationState.rawValue)" : "-")")
#endif
            return
        }
        var context: [String: Any] = [:]
        context["accessToken"] = accessToken
        context["refreshToken"] = refreshToken
        context["groupId"] = groupId
        context["isDarkMode"] = isDarkMode
        do {
            try WCSession.default.updateApplicationContext(context)
#if DEBUG
            print("[MoilWatchSync] 전송함 - groupId: \(groupId ?? "nil"), isDarkMode: \(isDarkMode)")
#endif
        } catch {
#if DEBUG
            print("[MoilWatchSync] 전송 실패 - \(error.localizedDescription)")
#endif
        }
    }
}

/// 워치가 직접 재발급한 토큰과, 재발급 전에 쓰던 refresh token입니다.
/// 아이폰은 자기 refresh token이 `previousRefreshToken`과 같을 때만(같은 세션일 때만) 받아들입니다.
struct MoilWatchTokens: Sendable {
    let accessToken: String
    let refreshToken: String
    let previousRefreshToken: String?

    nonisolated init?(context: [String: Any]) {
        guard let accessToken = context["watchAccessToken"] as? String, !accessToken.isEmpty,
              let refreshToken = context["watchRefreshToken"] as? String, !refreshToken.isEmpty else { return nil }
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        previousRefreshToken = context["watchPreviousRefreshToken"] as? String
    }
}

extension MoilWatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        guard activationState == .activated else { return }
        let tokens = MoilWatchTokens(context: session.receivedApplicationContext)
        Task { @MainActor in
            let manager = MoilWatchConnectivityManager.shared
            // 워치가 먼저 재발급해 둔 토큰이 있으면, 아이폰의 옛 토큰을 워치로 보내기 전에 먼저 받아들입니다.
            if let tokens { manager.onTokensFromWatch?(tokens) }
            manager.onActivated?()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let tokens = MoilWatchTokens(context: applicationContext) else { return }
        Task { @MainActor in
            MoilWatchConnectivityManager.shared.onTokensFromWatch?(tokens)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard message["type"] as? String == "requestSession" else {
            replyHandler([:])
            return
        }
        Task { @MainActor in
            let tokens = await MoilWatchConnectivityManager.shared.sessionProvider?()
            var reply: [String: Any] = [:]
            reply["accessToken"] = tokens?.accessToken
            reply["refreshToken"] = tokens?.refreshToken
            replyHandler(reply)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) { }
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
