import XCTest
@testable import taskOS

// MARK: - AuthenticationService

final class AuthenticationServiceTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "current_user")
    }

    func test_initialState() {
        let service = AuthenticationService()
        XCTAssertNil(service.currentUser)
        XCTAssertFalse(service.isAuthenticated)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.errorMessage)
    }

    func test_isAuthenticated_reflectsCurrentUser() {
        let service = AuthenticationService()
        XCTAssertFalse(service.isAuthenticated)
        service.currentUser = makeUser()
        XCTAssertTrue(service.isAuthenticated)
    }

    func test_signOut_clearsUserAndAuth() {
        let service = AuthenticationService()
        service.currentUser = makeUser()
        service.signOut()
        XCTAssertNil(service.currentUser)
        XCTAssertFalse(service.isAuthenticated)
    }

    func test_signOut_removesUserDefaultsEntry() throws {
        UserDefaults.standard.set(try encodedPersistedUser(), forKey: "current_user")
        let service = AuthenticationService()
        service.signOut()
        XCTAssertNil(UserDefaults.standard.data(forKey: "current_user"))
    }

    func test_restoreSession_decodesValidPersistedUser() throws {
        UserDefaults.standard.set(try encodedPersistedUser(), forKey: "current_user")
        let service = AuthenticationService()
        service.restoreSession()
        let user = try XCTUnwrap(service.currentUser)
        XCTAssertEqual(user.uid, "test-uid")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.provider, .apple)
    }

    func test_restoreSession_nilWhenNoData() {
        let service = AuthenticationService()
        service.restoreSession()
        XCTAssertNil(service.currentUser)
    }

    func test_restoreSession_nilWhenDataIsCorrupt() {
        UserDefaults.standard.set(Data([0xFF, 0xFE, 0x00]), forKey: "current_user")
        let service = AuthenticationService()
        service.restoreSession()
        XCTAssertNil(service.currentUser)
    }

    func test_googleSignIn_throwsWithoutFirebase() async {
        let service = AuthenticationService()
        do {
            _ = try await service.signInWithGoogle(presentingViewController: .init())
            XCTFail("Expected error")
        } catch let e as AuthError {
            guard case .unknown = e else { return XCTFail("Wrong error: \(e)") }
        } catch { XCTFail("Unexpected error type: \(error)") }
    }

    func test_emailSignIn_throwsWithoutFirebase() async {
        let service = AuthenticationService()
        do {
            _ = try await service.signInWithEmail(email: "t@t.com", password: "pw")
            XCTFail("Expected error")
        } catch let e as AuthError {
            guard case .unknown = e else { return XCTFail("Wrong error: \(e)") }
        } catch { XCTFail("Unexpected error type: \(error)") }
    }

    func test_createAccount_throwsWithoutFirebase() async {
        let service = AuthenticationService()
        do {
            _ = try await service.createAccount(email: "n@t.com", password: "pw", displayName: "N")
            XCTFail("Expected error")
        } catch let e as AuthError {
            guard case .unknown = e else { return XCTFail("Wrong error: \(e)") }
        } catch { XCTFail("Unexpected error type: \(error)") }
    }

    func test_passwordReset_throwsWithoutFirebase() async {
        let service = AuthenticationService()
        do {
            try await service.sendPasswordReset(email: "t@t.com")
            XCTFail("Expected error")
        } catch let e as AuthError {
            guard case .unknown = e else { return XCTFail("Wrong error: \(e)") }
        } catch { XCTFail("Unexpected error type: \(error)") }
    }

    // MARK: - Helpers

    private func makeUser() -> AppUser {
        AppUser(uid: "u1", email: "a@a.com", displayName: "A", photoURL: nil, provider: .apple)
    }

    private func encodedPersistedUser() throws -> Data {
        struct P: Codable {
            let uid, provider: String
            let email, displayName, photoURLString: String?
        }
        return try JSONEncoder().encode(
            P(uid: "test-uid", provider: "apple.com",
              email: "test@example.com", displayName: "Test", photoURLString: nil)
        )
    }
}

// MARK: - AppUser

final class AppUserTests: XCTestCase {

    func test_initials_fullName()      { XCTAssertEqual(user("John Doe").initials, "JD") }
    func test_initials_singleName()    { XCTAssertEqual(user("Alice").initials, "A") }
    func test_initials_nilName()       { XCTAssertEqual(userNoName(email: "bob@x.com").initials, "B") }
    func test_initials_bothNil()       { XCTAssertEqual(AppUser(uid:"u",email:nil,displayName:nil,photoURL:nil,provider:.apple).initials, "?") }
    func test_firstName_fromFullName() { XCTAssertEqual(user("Jane Smith").firstName, "Jane") }
    func test_firstName_nilName()      { XCTAssertEqual(userNoName(email: "t@t.com").firstName, "") }

    func test_equality() {
        let a = user("A", uid: "x")
        let b = user("A", uid: "x")
        let c = user("A", uid: "y")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    private func user(_ name: String, uid: String = "u1") -> AppUser {
        AppUser(uid: uid, email: "a@a.com", displayName: name, photoURL: nil, provider: .apple)
    }
    private func userNoName(email: String) -> AppUser {
        AppUser(uid: "u", email: email, displayName: nil, photoURL: nil, provider: .email)
    }
}

// MARK: - AuthError

final class AuthErrorTests: XCTestCase {

    func test_allCases_haveDescriptions() {
        let errors: [AuthError] = [
            .signInCancelled, .noIDToken, .invalidCredential, .networkError,
            .userNotFound, .wrongPassword, .emailAlreadyInUse, .weakPassword,
            .unknown("msg")
        ]
        for error in errors {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "Empty description for \(error)")
        }
    }

    func test_unknown_carriesMessage() {
        XCTAssertEqual(AuthError.unknown("Custom").errorDescription, "Custom")
    }
}

// MARK: - AuthProvider

final class AuthProviderTests: XCTestCase {

    func test_rawValues() {
        XCTAssertEqual(AuthProvider.apple.rawValue,  "apple.com")
        XCTAssertEqual(AuthProvider.google.rawValue, "google.com")
        XCTAssertEqual(AuthProvider.email.rawValue,  "password")
    }

    func test_codableRoundTrip() throws {
        for provider in [AuthProvider.apple, .google, .email] {
            let decoded = try JSONDecoder().decode(
                AuthProvider.self,
                from: try JSONEncoder().encode(provider)
            )
            XCTAssertEqual(decoded, provider)
        }
    }
}
