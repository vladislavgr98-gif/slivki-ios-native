import Foundation

public protocol HTTPDataSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPDataSession {}

public struct APIClient {
    public var baseURL: URL
    private let session: HTTPDataSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let accessToken: () -> String?

    public init(
        baseURL: URL = URL(string: "https://slivki-shop.ru/api/mobile/v1")!,
        session: HTTPDataSession = URLSession.shared,
        decoder: JSONDecoder = .slivki,
        encoder: JSONEncoder = .slivki,
        accessToken: @escaping () -> String? = { nil }
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.accessToken = accessToken
    }

    public func get<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        try await send(endpoint, method: "GET", body: Optional<Data>.none)
    }

    public func post<Body: Encodable, Response: Decodable>(_ endpoint: APIEndpoint, body: Body) async throws -> Response {
        let encoded = try encode(body)

        return try await send(endpoint, method: "POST", body: encoded)
    }

    public func put<Body: Encodable, Response: Decodable>(_ endpoint: APIEndpoint, body: Body) async throws -> Response {
        let encoded = try encode(body)

        return try await send(endpoint, method: "PUT", body: encoded)
    }

    public func delete<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response {
        try await send(endpoint, method: "DELETE", body: Optional<Data>.none)
    }

    public func postNoResponse<Body: Encodable>(_ endpoint: APIEndpoint, body: Body) async throws {
        let encoded = try encode(body)
        try await sendNoResponse(endpoint, method: "POST", body: encoded)
    }

    private func send<T: Decodable>(_ endpoint: APIEndpoint, method: String, body: Data?) async throws -> T {
        let (data, http) = try await rawSend(endpoint, method: method, body: body)

        if !(200...299).contains(http.statusCode) {
            throw decodeServerError(from: data) ?? APIError.httpStatus(http.statusCode)
        }

        do {
            if let envelope = try? decoder.decode(APIEnvelope<T>.self, from: data) {
                guard envelope.success else {
                    throw envelope.apiError ?? APIError.invalidResponse
                }
                guard let payload = envelope.data else {
                    throw APIError.invalidResponse
                }
                return payload
            }

            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingFailed(error.localizedDescription)
        }
    }

    private func sendNoResponse(_ endpoint: APIEndpoint, method: String, body: Data?) async throws {
        let (data, http) = try await rawSend(endpoint, method: method, body: body)

        guard (200...299).contains(http.statusCode) else {
            throw decodeServerError(from: data) ?? APIError.httpStatus(http.statusCode)
        }
    }

    private func rawSend(_ endpoint: APIEndpoint, method: String, body: Data?) async throws -> (Data, HTTPURLResponse) {
        var components = URLComponents(url: baseURL.appending(path: endpoint.path), resolvingAgainstBaseURL: false)
        components?.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = accessToken(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            return (data, http)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkUnavailable(error.localizedDescription)
        }
    }

    private func decodeServerError(from data: Data) -> APIError? {
        guard !data.isEmpty else {
            return nil
        }

        if let envelope = try? decoder.decode(APIEnvelope<EmptyPayload>.self, from: data), let apiError = envelope.apiError {
            return apiError
        }

        return nil
    }

    private func encode<Body: Encodable>(_ body: Body) throws -> Data {
        do {
            return try encoder.encode(body)
        } catch {
            throw APIError.encodingFailed(error.localizedDescription)
        }
    }
}

public extension JSONDecoder {
    static var slivki: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom(Self.decodeDate)
        return decoder
    }

    private static func decodeDate(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        if let timestamp = try? container.decode(Double.self) {
            return Date(timeIntervalSince1970: timestamp)
        }

        let value = try container.decode(String.self)
        let formatters = [
            ISO8601DateFormatter.slivki,
            ISO8601DateFormatter.slivkiFractional
        ]

        for formatter in formatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unsupported date format: \(value)"
        )
    }
}

private extension ISO8601DateFormatter {
    static let slivki: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let slivkiFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

public extension JSONEncoder {
    static var slivki: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
