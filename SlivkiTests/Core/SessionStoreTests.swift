import XCTest
@testable import Slivki

@MainActor
final class SessionStoreTests: XCTestCase {
    func testApplyLoginStoresTokenAndUser() throws {
        let tokenStore = InMemoryTokenStore()
        let session = SessionStore(tokenStore: tokenStore)
        let user = User(id: "1", name: "Покупатель", phone: "+375000000000")

        try session.applyLogin(token: "token", user: user)

        XCTAssertTrue(session.isAuthenticated)
        XCTAssertEqual(session.currentUser, user)
        XCTAssertEqual(tokenStore.loadToken(), "token")
    }

    func testStoredTokenAloneIsNotAuthenticatedUntilUserLoads() {
        let tokenStore = InMemoryTokenStore(token: "token")
        let session = SessionStore(tokenStore: tokenStore)

        session.restore()

        XCTAssertTrue(session.hasStoredToken)
        XCTAssertFalse(session.isAuthenticated)
        XCTAssertNil(session.currentUser)
    }

    func testLogoutClearsTokenAndUser() throws {
        let tokenStore = InMemoryTokenStore(token: "token")
        let session = SessionStore(tokenStore: tokenStore, currentUser: User(id: "1", name: "Покупатель"))

        session.logout()

        XCTAssertFalse(session.isAuthenticated)
        XCTAssertNil(session.currentUser)
        XCTAssertNil(tokenStore.loadToken())
    }
}
