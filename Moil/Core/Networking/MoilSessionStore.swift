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
        accessToken = tokens.accessToken
        refreshToken = tokens.refreshToken
        UserDefaults.standard.set(tokens.accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(tokens.refreshToken, forKey: refreshTokenKey)
    }

    func refreshSession() async -> Bool {
        guard let refreshToken, !refreshToken.isEmpty else { return false }
        do {
            let tokens = try await service().refreshToken(refreshToken)
            save(tokens)
            return true
        } catch {
            clear()
            return false
        }
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }
}
