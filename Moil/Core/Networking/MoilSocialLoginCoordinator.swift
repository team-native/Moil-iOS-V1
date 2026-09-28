import AuthenticationServices
import Foundation
import UIKit

/// Starts the server-managed OAuth flow and receives the app redirect after it completes.
/// The backend redirects each provider callback to
/// `moil://oauth/{provider}/callback?accessToken=...&refreshToken=...`.
@MainActor
final class MoilSocialLoginCoordinator: NSObject {
    private var session: ASWebAuthenticationSession?

    func login(provider: MoilSocialLoginProvider) async throws -> MoilTokenResponse {
        guard let authorizationURL = URL(string: "oauth/\(provider.rawValue)", relativeTo: MoilAPIConfiguration.baseURL) else {
            throw MoilAPIError.invalidResponse
        }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authorizationURL, callbackURLScheme: "moil") { [weak self] callbackURL, error in
                self?.session = nil
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: MoilAPIError.invalidResponse)
                    return
                }
                do {
                    continuation.resume(returning: try MoilTokenResponse(callbackURL: callbackURL))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.session = session

            guard session.start() else {
                self.session = nil
                continuation.resume(throwing: MoilAPIError.invalidResponse)
                return
            }
        }
    }
}

extension MoilSocialLoginCoordinator: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first(where: { $0.activationState == .foregroundActive })?.keyWindow ?? ASPresentationAnchor()
    }
}

enum MoilSocialLoginProvider: String {
    case google
    case kakao
    case apple

    init?(buttonName: String) {
        switch buttonName {
        case "구글": self = .google
        case "카카오": self = .kakao
        case "애플": self = .apple
        default: return nil
        }
    }
}

private extension MoilTokenResponse {
    init(callbackURL: URL) throws {
        let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
        let fragment = callbackURL.fragment ?? ""
        let fragmentItems = URLComponents(string: "?\(fragment)")?.queryItems ?? []
        let values = Dictionary(uniqueKeysWithValues: ((components?.queryItems ?? []) + fragmentItems).compactMap { item in
            item.value.map { (item.name, $0) }
        })
        if let error = values["error"], !error.isEmpty {
            throw MoilOAuthCallbackError(message: values["error_description"] ?? error)
        }
        guard let accessToken = values["accessToken"] ?? values["access_token"], !accessToken.isEmpty else {
            throw MoilAPIError.server(message: "소셜 로그인 토큰을 받지 못했어요.", statusCode: 0)
        }
        self.init(accessToken: accessToken, refreshToken: values["refreshToken"] ?? values["refresh_token"])
    }
}

private struct MoilOAuthCallbackError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
