import XCTest
@testable import taskOS

final class AuthServiceTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "current_user")
    }

    func testInitialState() {
        let s = AuthenticationService()
        XCTAssertNil(s.currentUser)
        XCTAssertFalse(s.isAuthenticated)
        XCTAssertFalse(s.isLoading)
        XCTAssertNil(s.errorMessage)
    }

    func testIsAuthenticatedReflectsUser() {
        let s = AuthenticationService()
        XCTAssertFalse(s.isAuthenticated)
        s.currentUser = AppUser(uid: "u1", email: "a@a.com", displayName: "A", photoURL: nil, provider: .apple)
        XCTAssertTrue(s.isAuthenticated)
    }

    func testSignOutClearsUser() {
        let s = AuthenticationService()
        s.currentUser = AppUser(uid: "u1", email: "a@a.com", displayName: "A", photoURL: nil, provider: .apple)
        s.signOut()
        XCTAssertNil(s.currentUser)
        XCTAssertFalse(s.isAuthenticated)
    }

    func testSignOutRemovesUserDefaults() throws {
        struct P: Codable { let uid, provider: String; let email, displayName, photoURLString: String? }
        let data = try JSONEncoder().encode(P(uid: "u1", provider: "apple.com", email: nil, displayName: nil, photoURLString: nil))
        UserDefaults.standard.set(data, forKey: "current_user")
        AuthenticationService().signOut()
        XCTAssertNil(UserDefaults.standard.data(forKey: "current_user"))
    }

    func testRestoreSessionDecodesValidUser() throws {
        struct P: Codable { let uid, provider: String; let email, displayName, photoURLString: String? }
        let data = try JSONEncoder().encode(P(uid: "uid1", provider: "apple.com", email: "a@b.com", displayName: "Test", photoURLString: nil))
        UserDefaults.standard.set(data, forKey: "current_user")
        let s = AuthenticationService()
        s.restoreSession()
        let user = try XCTUnwrap(s.currentUser)
        XCTAssertEqual(user.uid, "uid1")
        XCTAssertEqual(user.email, "a@b.com")
        XCTAssertEqual(user.provider, .apple)
    }

    func testRestoreSessionNilWhenNoData() {
        let s = AuthenticationService()
        s.restoreSession()
        XCTAssertNil(s.currentUser)
    }

    func testRestoreSessionNilWhenCorrupt() {
        UserDefaults.standard.set(Data([0xFF, 0xFE]), forKey: "current_user")
        let s = AuthenticationService()
        s.restoreSession()
        XCTAssertNil(s.currentUser)
    }

    func testGoogleSignInThrowsWithoutFirebase() async {
        do {
            _ = try await AuthenticationService().signInWithGoogle(presentingViewController: .init())
            XCTFail("Expected error")
        } catch let e as AuthError {
            guard case .unknown = e else { return XCTFail("Wrong AuthError: \(e)") }
        } catch { XCTFail("Unexpected: \(error)") }
    }

    func testEmailSignInThrowsWithoutFirebase() async {
        do {
            _ = try await AuthenticationService().signInWithEmail(email: "t@t.com", password: "pw")
            XCTFail("Expected error")
        } catch let e as AuthError {
            guard case .unknown = e else { return XCTFail("Wrong AuthError: \(e)") }
        } catch { XCTFail("Unexpected: \(error)") }
    }

    func testCreateAccountThrowsWithoutFirebase() async {
        do {
            _ = try await AuthenticationService().createAccount(email: "t@t.com", password: "pw", displayName: "T")
            XCTFail("Expected error")
        } catch let e as AuthError {
            guard case .unknown = e else { return XCTFail("Wrong AuthError: \(e)") }
        } catch { XCTFail("Unexpected: \(error)") }
    }

    func testPasswordResetThrowsWithoutFirebase() async {
        do {
            try await AuthenticationService().sendPasswordReset(email: "t@t.com")
            XCTFail("Expected error")
        } catch let e as AuthError {
            guard case .unknown = e else { return XCTFail("Wrong AuthError: \(e)") }
        } catch { XCTFail("Unexpected: \(error)") }
    }
}

final class AppUserTests: XCTestCase {

    func testInitialsFullName()   { XCTAssertEqual(u("John Doe").initials, "JD") }
    func testInitialsSingleName() { XCTAssertEqual(u("Alice").initials, "A") }
    func testInitialsFromEmail()  { XCTAssertEqual(AppUser(uid:"u",email:"bob@x.com",displayName:nil,photoURL:nil,provider:.email).initials, "B") }
    func testInitialsBothNil()    { XCTAssertEqual(AppUser(uid:"u",email:nil,displayName:nil,photoURL:nil,provider:.apple).initials, "?") }
    func testFirstNameFullName()  { XCTAssertEqual(u("Jane Smith").firstName, "Jane") }
    func testFirstNameNil()       { XCTAssertEqual(AppUser(uid:"u",email:"t@t.com",displayName:nil,photoURL:nil,provider:.email).firstName, "") }

    func testEquality() {
        let a = u("A", uid: "x")
        let b = u("A", uid: "x")
        let c = u("A", uid: "y")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    private func u(_ name: String, uid: String = "u1") -> AppUser {
        AppUser(uid: uid, email: "a@a.com", displayName: name, photoURL: nil, provider: .apple)
    }
}

final class AuthErrorTests: XCTestCase {

    func testAllCasesHaveDescriptions() {
        let errors: [AuthError] = [.signInCancelled, .noIDToken, .invalidCredential,
            .networkError, .userNotFound, .wrongPassword, .emailAlreadyInUse,
            .weakPassword, .unknown("msg")]
        for e in errors {
            XCTAssertFalse(e.errorDescription?.isEmpty ?? true, "Empty description for \(e)")
        }
    }

    func testUnknownCarriesMessage() {
        XCTAssertEqual(AuthError.unknown("Custom").errorDescription, "Custom")
    }
}

final class AuthProviderTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(AuthProvider.apple.rawValue,  "apple.com")
        XCTAssertEqual(AuthProvider.google.rawValue, "google.com")
        XCTAssertEqual(AuthProvider.email.rawValue,  "password")
    }

    func testCodableRoundTrip() throws {
        for p in [AuthProvider.apple, .google, .email] {
            let decoded = try JSONDecoder().decode(AuthProvider.self, from: try JSONEncoder().encode(p))
            XCTAssertEqual(decoded, p)
        }
    }
}
