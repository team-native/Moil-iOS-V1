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

struct MoilAPIClient {
    let session: URLSession
    let tokenProvider: () -> String?

    init(session: URLSession = .shared, tokenProvider: @escaping () -> String? = { nil }) {
        self.session = session
        self.tokenProvider = tokenProvider
    }

    func request<Response: Decodable, Body: Encodable>(
        _ path: String,
        method: String,
        body: Body? = nil,
        queryItems: [URLQueryItem] = [],
        requiresAuthentication: Bool = true
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
        guard let httpResponse = response as? HTTPURLResponse else { throw MoilAPIError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder.moil.decode(MoilServerError.self, from: data).message) ?? "요청에 실패했어요."
            throw MoilAPIError.server(message: message, statusCode: httpResponse.statusCode)
        }
        if data.isEmpty, Response.self == MoilEmptyResponse.self {
            return MoilEmptyResponse() as! Response
        }
        do {
            return try JSONDecoder.moil.decode(MoilAPIEnvelope<Response>.self, from: data).data
        } catch {
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
    let data: Value

    private enum CodingKeys: String, CodingKey { case data }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard container.contains(.data) else { throw MoilAPIError.decoding }
        data = try container.decode(Value.self, forKey: .data)
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

struct MoilEmptyResponse: Decodable { }
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
