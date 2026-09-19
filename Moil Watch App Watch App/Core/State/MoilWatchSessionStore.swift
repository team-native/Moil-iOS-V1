import Combine
import Foundation
import WatchConnectivity

/// 아이폰(Moil-iOS-V1)이 WatchConnectivity로 보내주는 로그인 세션과 선택된 그룹을 받아
/// 저장합니다. 워치 앱은 자체 로그인 화면이 없고, 이 세션을 그대로 이어받아 서버에 접속합니다.
@MainActor
final class MoilWatchSessionStore: NSObject, ObservableObject {
    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?
    @Published private(set) var groupId: String?
    /// 아이폰의 화이트/다크 모드 설정을 그대로 물려받습니다. 워치에는 별도의 설정 화면이 없습니다.
    @Published private(set) var isDarkMode = true

    private let accessTokenKey = "moilAccessToken"
    private let refreshTokenKey = "moilRefreshToken"
    private let groupIdKey = "moilGroupId"
    private let isDarkModeKey = "moilDarkMode"
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
            guard let self, let refreshToken = self.refreshToken, !refreshToken.isEmpty else { return false }
            do {
                let tokens = try await self.service().refreshToken(refreshToken)
                self.apply(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken ?? refreshToken, groupId: nil, isDarkMode: nil)
                return true
            } catch {
                return false
            }
        }
        refreshTask = task
        let didRefresh = await task.value
        refreshTask = nil
        return didRefresh
    }

    private func apply(accessToken: String?, refreshToken: String?, groupId: String?, isDarkMode: Bool?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        if let groupId { self.groupId = groupId }
        if let isDarkMode { self.isDarkMode = isDarkMode }
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        if let groupId { UserDefaults.standard.set(groupId, forKey: groupIdKey) }
        if let isDarkMode { UserDefaults.standard.set(isDarkMode, forKey: isDarkModeKey) }
    }
}

extension MoilWatchSessionStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        guard activationState == .activated else { return }
        let context = session.receivedApplicationContext
        guard !context.isEmpty else { return }
        Task { @MainActor [weak self] in
            self?.apply(
                accessToken: context["accessToken"] as? String,
                refreshToken: context["refreshToken"] as? String,
                groupId: context["groupId"] as? String,
                isDarkMode: context["isDarkMode"] as? Bool
            )
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor [weak self] in
            self?.apply(
                accessToken: applicationContext["accessToken"] as? String,
                refreshToken: applicationContext["refreshToken"] as? String,
                groupId: applicationContext["groupId"] as? String,
                isDarkMode: applicationContext["isDarkMode"] as? Bool
            )
        }
    }
}
