import Foundation

public enum CallFirstStep: String, Equatable, Sendable {
    case phone
    case call
    case email
    case register
}

public struct CallFirstAuthFlowState: Equatable, Sendable {
    public var step: CallFirstStep = .phone
    public var mode: String = ""
    public var phone: String = ""
    public var maskedPhone: String = ""
    public var callPhone: String = ""
    public var callPhonePretty: String = ""
    public var hasEmailFallback = false
    public var maskedEmail: String = ""
    public var emailCodeSent = false
    public var verified = false

    public init() {}
}

public struct CallFirstAuthResponse: Decodable, Equatable, Sendable {
    public let error: Bool
    public let success: Bool?
    public let redirect: String?
    public let pending: Bool?
    public let state: String?
    public let mode: String?
    public let maskedPhone: String?
    public let phone: String?
    public let callPhone: String?
    public let callPhonePretty: String?
    public let hasEmailFallback: Bool?
    public let maskedEmail: String?
    public let emailCodeSent: Bool?
    public let verified: Bool?
    public let errors: [String: String]?
}

public enum CallFirstAuthError: Error, Equatable, LocalizedError {
    case requestFailed(String)
    case serverErrors([String: String])

    public var errorDescription: String? {
        switch self {
        case .requestFailed(let message):
            message
        case .serverErrors(let errors):
            errors.values.joined(separator: "\n")
        }
    }
}

public struct CallFirstAuthService {
    public static let webSessionToken = "cms-web-session"

    private let endpoint: URL
    private let session: HTTPDataSession
    private let decoder: JSONDecoder

    public init(
        endpoint: URL = URL(string: "https://slivki-shop.ru/auth/login")!,
        session: HTTPDataSession = URLSession.shared,
        decoder: JSONDecoder = .slivki
    ) {
        self.endpoint = endpoint
        self.session = session
        self.decoder = decoder
    }

    public func start(phone: String) async throws -> CallFirstAuthFlowState {
        let normalized = Self.normalizePhone(phone)
        let response = try await post(action: "start", fields: ["phone": normalized])
        return try apply(response, to: CallFirstAuthFlowState())
    }

    public func status(current: CallFirstAuthFlowState) async throws -> CallFirstAuthFlowState {
        let response = try await post(action: "status")
        return try apply(response, to: current)
    }

    public func sendEmailCode(current: CallFirstAuthFlowState) async throws -> CallFirstAuthFlowState {
        let response = try await post(action: "email_send")
        return try apply(response, to: current)
    }

    public func verifyEmailCode(_ code: String, current: CallFirstAuthFlowState) async throws -> CallFirstAuthFlowState {
        let response = try await post(action: "email_verify", fields: ["code": code])
        return try apply(response, to: current)
    }

    public func register(name: String, email: String, current: CallFirstAuthFlowState) async throws -> CallFirstAuthFlowState {
        let response = try await post(
            action: "register",
            fields: [
                "nickname": name.trimmingCharacters(in: .whitespacesAndNewlines),
                "email": email.trimmingCharacters(in: .whitespacesAndNewlines)
            ]
        )
        return try apply(response, to: current)
    }

    public func reset() async throws -> CallFirstAuthFlowState {
        _ = try await post(action: "reset")
        return CallFirstAuthFlowState()
    }

    public static func normalizePhone(_ raw: String) -> String {
        var phone = raw.filter(\.isNumber)

        if phone.count == 10 {
            phone = "7" + phone
        }

        if phone.count == 11, phone.first == "8" {
            phone = "7" + phone.dropFirst()
        }

        return phone
    }

    public static func formatPhone(_ raw: String) -> String {
        let phone = normalizePhone(raw)
        guard phone.count == 11 else {
            return raw
        }

        let start = phone.index(phone.startIndex, offsetBy: 1)
        let areaEnd = phone.index(start, offsetBy: 3)
        let midEnd = phone.index(areaEnd, offsetBy: 3)
        let tailEnd = phone.index(midEnd, offsetBy: 2)

        return "+7 (\(phone[start..<areaEnd])) \(phone[areaEnd..<midEnd])-\(phone[midEnd..<tailEnd])-\(phone[tailEnd...])"
    }

    public static func isValidPhone(_ raw: String) -> Bool {
        normalizePhone(raw).count == 11
    }

    private func post(action: String, fields: [String: String] = [:]) async throws -> CallFirstAuthResponse {
        var payload = fields
        payload["auth_flow"] = "call_first_shop"
        payload["call_first_action"] = action
        payload["component"] = "shop"

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = formBody(payload)
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json, text/javascript, */*; q=0.01", forHTTPHeaderField: "Accept")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CallFirstAuthError.requestFailed("Не удалось связаться с сервером.")
        }

        let decoded: CallFirstAuthResponse
        do {
            decoded = try decoder.decode(CallFirstAuthResponse.self, from: data)
        } catch {
            throw CallFirstAuthError.requestFailed("Некорректный ответ сервера.")
        }

        if decoded.error {
            throw CallFirstAuthError.serverErrors(decoded.errors ?? ["common": "Не удалось выполнить запрос."])
        }

        return decoded
    }

    private func apply(_ response: CallFirstAuthResponse, to current: CallFirstAuthFlowState) throws -> CallFirstAuthFlowState {
        if let redirect = response.redirect, !redirect.isEmpty {
            var completed = current
            completed.verified = true
            completed.step = .phone
            return completed
        }

        var next = current
        if let state = response.state, let step = CallFirstStep(rawValue: state) {
            next.step = step
        }
        if let mode = response.mode {
            next.mode = mode
        }
        if let phone = response.phone, !phone.isEmpty {
            next.phone = phone
        }
        if let maskedPhone = response.maskedPhone {
            next.maskedPhone = maskedPhone
        }
        if let callPhone = response.callPhone {
            next.callPhone = callPhone
        }
        if let callPhonePretty = response.callPhonePretty {
            next.callPhonePretty = callPhonePretty
        }
        if let hasEmailFallback = response.hasEmailFallback {
            next.hasEmailFallback = hasEmailFallback
        }
        if let maskedEmail = response.maskedEmail {
            next.maskedEmail = maskedEmail
        }
        if let emailCodeSent = response.emailCodeSent {
            next.emailCodeSent = emailCodeSent
        }
        if let verified = response.verified {
            next.verified = verified
        }

        return next
    }

    private func formBody(_ fields: [String: String]) -> Data {
        let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+"))
        let pairs = fields.map { key, value -> String in
            let encoded = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
            return "\(key)=\(encoded)"
        }
        return Data(pairs.joined(separator: "&").utf8)
    }

    public func exchangeMobileToken(
        baseURL: URL = URL(string: "https://slivki-shop.ru/api/mobile/v1")!
    ) async throws -> LoginResponse {
        let client = APIClient(baseURL: baseURL, session: session, accessToken: { nil })
        return try await client.post(.login, body: MobileSessionLoginRequest())
    }
}

private struct MobileSessionLoginRequest: Encodable {
    let grantType = "web_session"
}

public extension CallFirstAuthResponse {
    var completedLogin: Bool {
        redirect?.isEmpty == false || success == true
    }
}
