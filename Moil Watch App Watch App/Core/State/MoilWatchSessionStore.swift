import Combine
import Foundation
import WatchConnectivity

/// 아이폰(Moil-iOS-V1)이 WatchConnectivity로 보내주는 로그인 세션과 선택된 그룹을 받아
/// 저장합니다. 워치 앱은 자체 로그인 화면이 없고, 이 세션을 그대로 이어받아 서버에 접속합니다.
///
/// 서버는 토큰을 재발급할 때 이전 세션을 지웁니다. 아이폰과 워치가 같은 세션을 쓰므로
/// 401을 받으면 먼저 아이폰에 최신 토큰을 묻고, 아이폰이 닿지 않을 때만 직접 재발급한 뒤
/// 새 토큰을 아이폰에 남겨 아이폰 세션이 끊기지 않게 합니다.
@MainActor
final class MoilWatchSessionStore: NSObject, ObservableObject {
    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?
    @Published private(set) var groupId: String?
    /// 아이폰의 화이트/다크 모드 설정을 그대로 물려받습니다. 워치에는 별도의 설정 화면이 없습니다.
    @Published private(set) var isDarkMode = true
    /// 아이폰에서도 세션을 받지 못해 다시 로그인이 필요한 상태입니다.
    @Published private(set) var needsPhoneSession = false

    private let accessTokenKey = "moilAccessToken"
    private let refreshTokenKey = "moilRefreshToken"
    private let groupIdKey = "moilGroupId"
    private let isDarkModeKey = "moilDarkMode"
    /// 마지막으로 반영한 아이폰 context의 refresh token입니다. 워치가 그 뒤 직접 재발급했다면
    /// 앱을 다시 켤 때 남아 있는 옛 context로 되돌아가지 않도록 비교에 씁니다.
    private let lastPhoneRefreshTokenKey = "moilLastPhoneRefreshToken"
    private var refreshTask: Task<Bool, Never>?

    override init() {
        super.init()
        accessToken = UserDefaults.standard.string(forKey: accessTokenKey)
        refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)
        groupId = UserDefaults.standard.string(forKey: groupIdKey)
        if UserDefaults.standard.object(forKey: isDarkModeKey) != nil {
            isDarkMode = UserDefaults.standard.bool(forKey: isDarkModeKey)
        }
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    var isAuthenticated: Bool { accessToken?.isEmpty == false }

    func service() -> MoilWatchAPIService {
        MoilWatchAPIService(
            tokenProvider: { [weak self] in self?.accessToken },
            tokenRefresher: { [weak self] in
                guard let self else { return false }
                return await self.refreshSession()
            }
        )
    }

    private func refreshSession() async -> Bool {
        if let refreshTask { return await refreshTask.value }
        let task = Task { [weak self] () -> Bool in
            guard let self else { return false }
            if await self.requestSessionFromPhone() { return true }
            return await self.refreshByItself()
        }
        refreshTask = task
        let didRefresh = await task.value
        refreshTask = nil
        needsPhoneSession = !didRefresh
        return didRefresh
    }

    /// 아이폰이 가까이 있으면 아이폰에 최신 토큰을 받습니다. 아이폰이 필요하면 재발급까지 해서 돌려줍니다.
    private func requestSessionFromPhone() async -> Bool {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              WCSession.default.isReachable else { return false }
        let reply: [String: Any]? = await withCheckedContinuation { continuation in
            let once = MoilOnce(continuation)
            WCSession.default.sendMessage(["type": "requestSession"], replyHandler: { once.resume($0) }, errorHandler: { _ in once.resume(nil) })
            Task {
                try? await Task.sleep(for: .seconds(6))
                once.resume(nil)
            }
        }
        guard let reply,
              let access = reply["accessToken"] as? String, !access.isEmpty,
              access != accessToken else { return false }
        applyFromPhone(accessToken: access, refreshToken: reply["refreshToken"] as? String, groupId: nil, isDarkMode: nil)
        return true
    }

    private func refreshByItself() async -> Bool {
        guard let previous = refreshToken, !previous.isEmpty else { return false }
        do {
            let tokens = try await service().refreshToken(previous, accessToken: accessToken)
            let newRefresh = tokens.refreshToken ?? previous
            store(accessToken: tokens.accessToken, refreshToken: newRefresh)
            shareWithPhone(accessToken: tokens.accessToken, refreshToken: newRefresh, previousRefreshToken: previous)
            return true
        } catch {
            return false
        }
    }

    /// 워치가 직접 재발급한 토큰을 아이폰에 남깁니다. 아이폰 앱이 꺼져 있어도 다음에 켜질 때 받습니다.
    private func shareWithPhone(accessToken: String, refreshToken: String, previousRefreshToken: String) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        try? WCSession.default.updateApplicationContext([
            "watchAccessToken": accessToken,
            "watchRefreshToken": refreshToken,
            "watchPreviousRefreshToken": previousRefreshToken,
        ])
    }

    private func store(accessToken: String?, refreshToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
    }

    fileprivate func applyFromPhone(accessToken: String?, refreshToken: String?, groupId: String?, isDarkMode: Bool?) {
#if DEBUG
        print("[MoilWatchSync] 받음 - groupId: \(groupId ?? "nil"), isDarkMode: \(isDarkMode.map(String.init) ?? "nil")")
#endif
        store(accessToken: accessToken, refreshToken: refreshToken)
        UserDefaults.standard.set(refreshToken, forKey: lastPhoneRefreshTokenKey)
        needsPhoneSession = false
        if let groupId {
            self.groupId = groupId
            UserDefaults.standard.set(groupId, forKey: groupIdKey)
        }
        if let isDarkMode {
            self.isDarkMode = isDarkMode
            UserDefaults.standard.set(isDarkMode, forKey: isDarkModeKey)
        }
    }

    /// 앱을 켤 때 남아 있는 아이폰 context가 이미 반영한 것과 같으면 토큰은 건드리지 않습니다.
    /// (그 사이 워치가 직접 재발급했다면 옛 토큰으로 되돌아가 401이 나기 때문입니다.)
    fileprivate func applyStoredPhoneContext(_ context: [String: Any]) {
        let refresh = context["refreshToken"] as? String
        let isAlreadyApplied = refresh != nil && refresh == UserDefaults.standard.string(forKey: lastPhoneRefreshTokenKey)
        if isAlreadyApplied, isAuthenticated {
            if let groupId = context["groupId"] as? String {
                self.groupId = groupId
                UserDefaults.standard.set(groupId, forKey: groupIdKey)
            }
            if let isDarkMode = context["isDarkMode"] as? Bool {
                self.isDarkMode = isDarkMode
                UserDefaults.standard.set(isDarkMode, forKey: isDarkModeKey)
            }
            return
        }
        applyFromPhone(
            accessToken: context["accessToken"] as? String,
            refreshToken: refresh,
            groupId: context["groupId"] as? String,
            isDarkMode: context["isDarkMode"] as? Bool
        )
    }
}

/// 응답·오류·시간 초과 중 먼저 온 것 하나만 continuation에 전달합니다.
private final class MoilOnce: @unchecked Sendable {
    private var continuation: CheckedContinuation<[String: Any]?, Never>?
    private let lock = NSLock()

    init(_ continuation: CheckedContinuation<[String: Any]?, Never>) {
        self.continuation = continuation
    }

    func resume(_ value: [String: Any]?) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(returning: value)
    }
}

extension MoilWatchSessionStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        guard activationState == .activated else { return }
        let context = session.receivedApplicationContext
        guard !context.isEmpty else { return }
        Task { @MainActor [weak self] in
            self?.applyStoredPhoneContext(context)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor [weak self] in
            self?.applyFromPhone(
                accessToken: applicationContext["accessToken"] as? String,
                refreshToken: applicationContext["refreshToken"] as? String,
                groupId: applicationContext["groupId"] as? String,
                isDarkMode: applicationContext["isDarkMode"] as? Bool
            )
        }
    }
}
