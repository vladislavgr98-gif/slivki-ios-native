import Combine
import Foundation

public struct User: Codable, Equatable, Identifiable {
    public let id: String
    public let name: String?
    public let phone: String?
    public let email: String?
    public let city: City?

    public var displayName: String {
        name ?? phone ?? email ?? "Покупатель"
    }

    public init(id: String, name: String? = nil, phone: String? = nil, email: String? = nil, city: City? = nil) {
        self.id = id
        self.name = name
        self.phone = phone
        self.email = email
        self.city = city
    }
}

public protocol TokenStoring {
    func loadToken() -> String?
    func saveToken(_ token: String) throws
    func clearToken() throws
}

public final class InMemoryTokenStore: TokenStoring {
    private var token: String?

    public init(token: String? = nil) {
        self.token = token
    }

    public func loadToken() -> String? {
        token
    }

    public func saveToken(_ token: String) throws {
        self.token = token
    }

    public func clearToken() throws {
        token = nil
    }
}

@MainActor
public final class SessionStore: ObservableObject {
    @Published public private(set) var currentUser: User?
    private let tokenStore: TokenStoring

    public var isAuthenticated: Bool {
        tokenStore.loadToken() != nil && currentUser != nil
    }

    public var hasStoredToken: Bool {
        tokenStore.loadToken() != nil
    }

    public var sessionToken: String? {
        tokenStore.loadToken()
    }

    public init(tokenStore: TokenStoring = KeychainStore(), currentUser: User? = nil) {
        self.tokenStore = tokenStore
        self.currentUser = currentUser
    }

    public func restore() {
        // A stored token only proves there may be a session. Bootstrap/login must
        // return a real user before the UI treats the user as authenticated.
    }

    public func applyLogin(token: String, user: User) throws {
        try tokenStore.saveToken(token)
        currentUser = user
    }

    public func applyWebSession(user: User) throws {
        try applyLogin(token: CallFirstAuthService.webSessionToken, user: user)
    }

    public func applyBootstrap(user: User?) {
        guard hasStoredToken else {
            return
        }
        currentUser = user
    }

    public func logout() {
        try? tokenStore.clearToken()
        currentUser = nil
    }

    public func syncMobileToken(using authService: CallFirstAuthService = CallFirstAuthService()) async {
        guard sessionToken == CallFirstAuthService.webSessionToken else {
            return
        }

        do {
            let response = try await authService.exchangeMobileToken()
            try applyLogin(token: response.accessToken, user: response.user)
        } catch {
            // Keep the web session marker until the next bootstrap refresh.
        }
    }
}
