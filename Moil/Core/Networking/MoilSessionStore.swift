import Foundation
import Combine

@MainActor
final class MoilSessionStore: ObservableObject {
    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?

    private let accessTokenKey = "moilAccessToken"
    private let refreshTokenKey = "moilRefreshToken"

    init() {
        accessToken = UserDefaults.standard.string(forKey: accessTokenKey)
        refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)
    }

    var isAuthenticated: Bool { accessToken?.isEmpty == false }

    func service() -> MoilAPIService {
        MoilAPIService { [weak self] in self?.accessToken }
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
        guard let refreshToken, !refreshToken.isEmpty else { return false }
        do {
            let tokens = try await service().refreshToken(refreshToken)
            save(tokens)
            return true
        } catch {
            if let apiError = error as? MoilAPIError, apiError.isAuthenticationFailure {
                clear()
                return false
            }

            // 일시적인 네트워크/응답 오류로 저장된 로그인 정보를 지우지 않습니다.
            return isAuthenticated
        }
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }
}
