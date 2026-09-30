import AuthenticationServices
import Foundation

/// 화면에 보여줄 오류 문구를 한국어로 맞춥니다.
/// 서버·시스템·소셜 로그인 제공자가 영어로 준 문구는 여기서 바꾸고,
/// 로그에는 원래 문구를 그대로 남깁니다.
enum MoilErrorMessage {
    static let fallback = "문제가 발생했어요. 잠시 후 다시 시도해주세요."
    private static let socialLoginFailed = "소셜 로그인에 실패했어요. 잠시 후 다시 시도해주세요."

    /// 서버 `message`를 화면용 문구로 바꿉니다. 이미 한국어면 그대로 씁니다.
    static func server(_ message: String, statusCode: Int) -> String {
        if message.containsHangul { return message }
        return knownServerMessage(message) ?? statusMessage(statusCode)
    }

    /// 소셜 로그인 콜백 URL의 `error`, `error_description` 값을 화면용 문구로 바꿉니다.
    static func socialLoginCallback(error: String, description: String?) -> String {
        switch error {
        case "access_denied", "user_cancelled_authorize":
            return "소셜 로그인을 취소했어요."
        default:
            break
        }
        guard let description, !description.isEmpty else { return socialLoginFailed }
        if description.containsHangul { return description }
        return knownServerMessage(description) ?? socialLoginFailed
    }

    static func network(_ code: URLError.Code) -> String {
        switch code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            "인터넷 연결을 확인해주세요."
        case .timedOut:
            "서버 응답이 늦어지고 있어요. 잠시 후 다시 시도해주세요."
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            "서버에 연결할 수 없어요. 잠시 후 다시 시도해주세요."
        case .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate,
             .serverCertificateNotYetValid, .serverCertificateHasUnknownRoot:
            "안전한 연결을 만들지 못했어요. 네트워크를 확인해주세요."
        case .cancelled:
            "요청이 취소되었어요."
        default:
            "네트워크 오류가 발생했어요. 잠시 후 다시 시도해주세요."
        }
    }

    /// 백엔드(Moil-Backend-V1)가 영어로 내려주는 문구입니다.
    /// 소셜 로그인 실패 문구는 `409 CONFLICT "..."`처럼 상태가 앞에 붙어 오므로 포함 여부로 비교합니다.
    private static func knownServerMessage(_ message: String) -> String? {
        if message.contains("already linked to another user") {
            return "이미 다른 모일 계정에 연결된 소셜 계정이에요."
        }
        if message.contains("is already linked to another") {
            return "이 계정에는 이미 다른 소셜 계정이 연결되어 있어요."
        }
        if message.contains("does not include email") {
            return "소셜 계정의 이메일 정보를 가져오지 못했어요. 이메일 제공에 동의한 뒤 다시 시도해주세요."
        }
        if message.contains("id_token") || message.contains("token response is empty")
            || message.contains("profile response is empty") || message.contains("public keys response is empty") {
            return socialLoginFailed
        }
        if message.contains("Invalid request") { return "입력한 내용을 다시 확인해주세요." }
        if message.contains("Resource not found") { return "요청한 정보를 찾을 수 없어요." }
        if message.contains("Unexpected server error") { return "서버에 문제가 생겼어요. 잠시 후 다시 시도해주세요." }
        return nil
    }

    /// 알 수 없는 영어 문구(예: `Bad Request` 같은 HTTP 기본 문구)는 상태 코드로 안내합니다.
    private static func statusMessage(_ statusCode: Int) -> String {
        switch statusCode {
        case 400: "입력한 내용을 다시 확인해주세요."
        case 401: "로그인 정보가 올바르지 않아요. 다시 로그인해주세요."
        case 403: "접근 권한이 없어요."
        case 404: "요청한 정보를 찾을 수 없어요."
        case 409: "이미 처리된 요청이에요."
        case 413: "파일 크기가 너무 커요."
        case 429: "요청이 너무 많아요. 잠시 후 다시 시도해주세요."
        case 500...: "서버에 문제가 생겼어요. 잠시 후 다시 시도해주세요."
        default: "요청에 실패했어요."
        }
    }
}

extension Error {
    /// 화면에 보여줄 한국어 오류 문구입니다. 로그에는 `localizedDescription` 대신 원본 오류를 남깁니다.
    var userFacingMessage: String {
        if let apiError = self as? MoilAPIError {
            return apiError.errorDescription ?? MoilErrorMessage.fallback
        }
        if let urlError = self as? URLError {
            return MoilErrorMessage.network(urlError.code)
        }
        if let authError = self as? ASWebAuthenticationSessionError {
            // 콜백 설정이나 서버 토큰 교환 실패도 취소(코드 1)로 오는 경우가 있어 재시도를 함께 안내합니다.
            return authError.code == .canceledLogin
                ? "로그인이 취소되었거나 완료되지 않았어요. 다시 시도해주세요."
                : MoilErrorMessage.fallback
        }
        let description = localizedDescription
        return description.containsHangul ? description : MoilErrorMessage.fallback
    }
}

private extension String {
    var containsHangul: Bool {
        unicodeScalars.contains { (0xAC00...0xD7A3).contains($0.value) || (0x3131...0x318E).contains($0.value) }
    }
}
