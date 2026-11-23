import Foundation
import Combine

@MainActor
final class MoilSessionStore: ObservableObject {
    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?
    /// 계정 기본 프로필. 그룹별 참여 프로필과 별개이며, 새 그룹 생성·참여 시 초기값으로 씁니다.
    @Published private(set) var accountProfile: MoilAccountProfile?

    private let accessTokenKey = "moilAccessToken"
    private let refreshTokenKey = "moilRefreshToken"
    private var refreshTask: Task<Bool, Never>?

    init() {
        accessToken = UserDefaults.standard.string(forKey: accessTokenKey)
        refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)
    }

    var isAuthenticated: Bool { accessToken?.isEmpty == false }
    var hasStoredSession: Bool {
        accessToken?.isEmpty == false || refreshToken?.isEmpty == false
    }

    func service() -> MoilAPIService {
        MoilAPIService(
            tokenProvider: { [weak self] in self?.accessToken },
            tokenRefresher: { [weak self] in
                guard let self else { return false }
                return await self.refreshSession()
            }
        )
    }

    func save(_ tokens: MoilTokenResponse) {
        // 일부 토큰 재발급 응답은 refreshToken을 다시 보내지 않습니다.
        // 그 경우 기존 refresh token을 유지해야 다음 앱 실행에서도 자동 로그인이 가능합니다.
        let retainedRefreshToken = tokens.refreshToken?.isEmpty == false
            ? tokens.refreshToken
            : refreshToken
        accessToken = tokens.accessToken
        refreshToken = retainedRefreshToken
        UserDefaults.standard.set(tokens.accessToken, forKey: accessTokenKey)
        if let retainedRefreshToken {
            UserDefaults.standard.set(retainedRefreshToken, forKey: refreshTokenKey)
        } else {
            UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        }
    }

    func refreshSession() async -> Bool {
        if let refreshTask { return await refreshTask.value }

        let task = Task { [weak self] in
            guard let self, let refreshToken = self.refreshToken, !refreshToken.isEmpty else { return false }
            do {
                let tokens = try await self.service().refreshToken(refreshToken, accessToken: self.accessToken)
                self.save(tokens)
                return true
            } catch {
                if let apiError = error as? MoilAPIError, apiError.isAuthenticationFailure {
                    // 워치가 같은 세션을 먼저 재발급했다면 아이폰 토큰은 이미 무효입니다.
                    // 워치가 남겨 둔 새 토큰이 있으면 로그아웃하지 않고 그 토큰으로 이어갑니다.
                    if let watchTokens = MoilWatchConnectivityManager.shared.latestTokensFromWatch(),
                       self.adopt(watchTokens) {
                        return true
                    }
                    self.clear()
                    return false
                }

                // 네트워크 장애일 때는 저장된 access token을 유지해 오프라인 진입을 막지 않습니다.
                return self.isAuthenticated
            }
        }
        refreshTask = task
        let didRefresh = await task.value
        refreshTask = nil
        return didRefresh
    }

    /// 워치가 직접 재발급한 토큰을 받아들입니다. 같은 세션에서 나온 토큰일 때만 반영합니다.
    @discardableResult
    func adopt(_ tokens: MoilWatchTokens) -> Bool {
        guard let current = refreshToken, !current.isEmpty,
              tokens.refreshToken != current,
              tokens.previousRefreshToken == current else { return false }
        accessToken = tokens.accessToken
        refreshToken = tokens.refreshToken
        UserDefaults.standard.set(tokens.accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(tokens.refreshToken, forKey: refreshTokenKey)
        return true
    }

    func loadAccountProfile() async {
        guard isAuthenticated else { return }
        if let profile = try? await service().myProfile() { accountProfile = profile }
    }

    func updateDefaultProfile(name: String, colorId: String?, imagePath: String?) async throws {
        accountProfile = try await service().updateDefaultProfile(name: name, colorId: colorId, imagePath: imagePath)
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
        accountProfile = nil
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }
}
