import Foundation

enum MoilAPIConfiguration {
    static let baseURL = URL(string: "https://moil.team-native.kr")!
}

enum MoilAPIError: LocalizedError {
    case invalidResponse
    case server(message: String, statusCode: Int)
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "서버 응답을 처리할 수 없어요."
        case let .server(message, _):
            message
        case .decoding:
            "서버 응답 형식이 올바르지 않아요."
        }
    }
}

extension MoilAPIError {
    var isAuthenticationFailure: Bool {
        guard case let .server(_, statusCode) = self else { return false }
        return statusCode == 401 || statusCode == 403
    }
}

extension Error {
    /// `.task(id:)`가 다시 실행되거나 화면이 사라지면서 요청이 취소된 경우입니다.
    /// 사용자가 만든 상황이 아니므로 오류로 보여주지 않습니다.
    var isRequestCancellation: Bool {
        if self is CancellationError { return true }
        if let urlError = self as? URLError { return urlError.code == .cancelled }
        return false
    }
}

struct MoilAPIClient {
    let session: URLSession
    let tokenProvider: () -> String?
    let tokenRefresher: (() async -> Bool)?

    init(
        session: URLSession = .shared,
        tokenProvider: @escaping () -> String? = { nil },
        tokenRefresher: (() async -> Bool)? = nil
    ) {
        self.session = session
        self.tokenProvider = tokenProvider
        self.tokenRefresher = tokenRefresher
    }

    func request<Response: Decodable, Body: Encodable>(
        _ path: String,
        method: String,
        body: Body? = nil,
        queryItems: [URLQueryItem] = [],
        requiresAuthentication: Bool = true
    ) async throws -> Response {
        do {
            return try await requestOnce(
                path,
                method: method,
                body: body,
                queryItems: queryItems,
                requiresAuthentication: requiresAuthentication
            )
        } catch let error as MoilAPIError where requiresAuthentication && error.isAuthenticationFailure {
            guard let tokenRefresher, await tokenRefresher() else { throw error }
            return try await requestOnce(
                path,
                method: method,
                body: body,
                queryItems: queryItems,
                requiresAuthentication: requiresAuthentication
            )
        }
    }

    private func requestOnce<Response: Decodable, Body: Encodable>(
        _ path: String,
        method: String,
        body: Body?,
        queryItems: [URLQueryItem],
        requiresAuthentication: Bool
    ) async throws -> Response {
        var components = URLComponents(url: MoilAPIConfiguration.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components?.url else { throw MoilAPIError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder.moil.encode(body)
        }
        if requiresAuthentication, let token = tokenProvider(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        return try Self.parse(data: data, response: response, path: path, method: method)
    }

    /// 이미지 업로드처럼 JSON이 아닌 `multipart/form-data` 요청에 사용합니다.
    /// 응답 처리(에러 메시지, envelope 언래핑)는 JSON 요청과 동일한 규칙을 따릅니다.
    func upload<Response: Decodable>(
        _ path: String,
        fieldName: String,
        filename: String,
        mimeType: String,
        data fileData: Data,
        requiresAuthentication: Bool = true
    ) async throws -> Response {
        do {
            return try await uploadOnce(
                path,
                fieldName: fieldName,
                filename: filename,
                mimeType: mimeType,
                data: fileData,
                requiresAuthentication: requiresAuthentication
            )
        } catch let error as MoilAPIError where requiresAuthentication && error.isAuthenticationFailure {
            guard let tokenRefresher, await tokenRefresher() else { throw error }
            return try await uploadOnce(
                path,
                fieldName: fieldName,
                filename: filename,
                mimeType: mimeType,
                data: fileData,
                requiresAuthentication: requiresAuthentication
            )
        }
    }

    private func uploadOnce<Response: Decodable>(
        _ path: String,
        fieldName: String,
        filename: String,
        mimeType: String,
        data fileData: Data,
        requiresAuthentication: Bool
    ) async throws -> Response {
        let url = MoilAPIConfiguration.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if requiresAuthentication, let token = tokenProvider(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        return try Self.parse(data: data, response: response, path: path, method: "POST")
    }

    private static func parse<Response: Decodable>(
        data: Data,
        response: URLResponse,
        path: String,
        method: String
    ) throws -> Response {
        guard let httpResponse = response as? HTTPURLResponse else { throw MoilAPIError.invalidResponse }
#if DEBUG
        print("[MoilAPI] \(method) /\(path) → \(httpResponse.statusCode)")
#endif
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder.moil.decode(MoilServerError.self, from: data).message) ?? "요청에 실패했어요."
            throw MoilAPIError.server(message: message, statusCode: httpResponse.statusCode)
        }
        if data.isEmpty, Response.self == MoilEmptyResponse.self {
            return MoilEmptyResponse() as! Response
        }
        do {
            let envelope = try JSONDecoder.moil.decode(MoilAPIEnvelope<Response>.self, from: data)
            guard envelope.success else {
                throw MoilAPIError.server(
                    message: envelope.message ?? "요청에 실패했어요.",
                    statusCode: envelope.status ?? httpResponse.statusCode
                )
            }
            if let value = envelope.data { return value }
            if Response.self == MoilEmptyResponse.self {
                return MoilEmptyResponse() as! Response
            }
            throw MoilAPIError.decoding
        } catch {
            if error is MoilAPIError { throw error }
            do {
                return try JSONDecoder.moil.decode(Response.self, from: data)
            } catch {
                throw MoilAPIError.decoding
            }
        }
    }

    func request<Response: Decodable>(
        _ path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        requiresAuthentication: Bool = true
    ) async throws -> Response {
        try await request(path, method: method, body: Optional<MoilEmptyRequestBody>.none, queryItems: queryItems, requiresAuthentication: requiresAuthentication)
    }

    func request<Body: Encodable>(
        _ path: String,
        method: String,
        body: Body? = nil,
        requiresAuthentication: Bool = true
    ) async throws {
        let _: MoilEmptyResponse = try await request(path, method: method, body: body, requiresAuthentication: requiresAuthentication)
    }
}

private struct MoilAPIEnvelope<Value: Decodable>: Decodable {
    let success: Bool
    let status: Int?
    let message: String?
    let data: Value?

    private enum CodingKeys: String, CodingKey { case success, status, message, data }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = (try? container.decode(Bool.self, forKey: .success)) ?? true
        status = try? container.decode(Int.self, forKey: .status)
        message = try? container.decode(String.self, forKey: .message)
        data = try container.decodeIfPresent(Value.self, forKey: .data)
    }
}

private struct MoilServerError: Decodable {
    let message: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = (try? container.decode(String.self, forKey: .message)) ?? "요청에 실패했어요."
    }

    private enum CodingKeys: String, CodingKey { case message }
}

/// Endpoints such as logout, event update, and event deletion return
/// `"data": null`.  A custom decoder deliberately accepts that null value.
struct MoilEmptyResponse: Decodable {
    init() { }

    init(from decoder: Decoder) throws { }
}
private struct MoilEmptyRequestBody: Encodable { }

extension JSONEncoder {
    static let moil: JSONEncoder = {
        let encoder = JSONEncoder()
        // The Moil server DTOs use camelCase request keys (for example verifyId and sessionId).
        encoder.keyEncodingStrategy = .useDefaultKeys
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension JSONDecoder {
    static let moil: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
