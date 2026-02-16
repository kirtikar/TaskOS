import XCTest
import XCTest
@testable import taskOS

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
        service.currentUser = AppUser(uid: "u1", email: "a@a.com", displayName: "A", photoURL: nil, provider: .apple)
        XCTAssertTrue(service.isAuthenticated)
    }

    func test_signOut_clearsUser() {
        let service = AuthenticationService()
        service.currentUser = AppUser(uid: "u1", email: "a@a.com", displayName: "A", photoURL: nil, provider: .apple)
        service.signOut()
        XCTAssertNil(service.currentUser)
        XCTAssertFalse(service.isAuthenticated)
    }

    func test_signOut_removesUserDefaults() throws {
        struct P: Codable { let uid, provider: String; let email, displayName, photoURLString: String? }
        let data = try JSONEncoder().encode(P(uid: "u1", provider: "apple.com", email: nil, displayName: nil, photoURLString: nil))
        UserDefaults.standard.set(data, forKey: "current_user")
        AuthenticationService().signOut()
        XCTAssertNil(UserDefaults.standard.data(forKey: "current_user"))
    }

    func test_restoreSession_decodesValidUser() throws {
        struct P: Codable { let uid, provider: String; let email, displayName, photoURLString: String? }
        let data = try JSONEncoder().encode(P(uid: "uid1", provider: "apple.com", email: "a@b.com", displayName: "Test", photoURLString: nil))
        UserDefaults.standard.set(data, forKey: "current_user")
        let service = AuthenticationService()
        service.restoreSession()
        let user = try XCTUnwrap(service.currentUser)
        XCTAssertEqual(user.uid, "uid1")
        XCTAssertEqual(user.email, "a@b.com")
        XCTAssertEqual(user.provider, .apple)
    }

    func test_restoreSession_nilWhenNoData() {
        let service = AuthenticationService()
        service.restoreSession()
        XCTAssertNil(service.currentUser)
    }

    func test_restoreSession_nilWhenCorrupt() {
        UserDefaults.standard.set(Data([0xFF, 0xFE]), forKey: "current_user")
        let service = AuthenticationService()
        service.restoreSession()
        XCTAssertNil(service.currentUser)
    }

    func test_googleSignIn_throwsWithoutFirebase() async {
        do {
            _ = try await AuthenticationService().signInWithGoogle(presentingViewController: .init())
            XCTFail("Expected error")
        } catch let e as AuthError {
            guard case .unknown = e else { return XCTFail("Wrong error: \(e)") }
        } catch { XCTFail("Unexpected: \(error)") }
    }

    func test_emailSignIn_throwsWithoutFirebase() async {
        do {
            _ = try await AuthenticationService().signInWithEmail(email: "t@t.com", password: "pw")
            XCTFail("Expected error")
        } catch let e as AuthError {
            guard case .unknown = e else { return XCTFail("Wrong error: \(e)") }
        } catch { XCTFail("Unexpected: \(error)") }
    }

    func test_createAccount_throwsWithoutFirebase() async {
        do {
            _ = try await AuthenticationService().createAccount(email: "t@t.com", password: "pw", displayName: "T")
            XCTFail("Expected error")
        } catch let e as AuthError {
            guard case .unknown = e else { return XCTFail("Wrong error: \(e)") }
        } catch { XCTFail("Unexpected: \(error)") }
    }

    func test_passwordReset_throwsWithoutFirebase() async {
        do {
            try await AuthenticationService().sendPasswordReset(email: "t@t.com")
            XCTFail("Expected error")
        } catch let e as AuthError {
            guard case .unknown = e else { return XCTFail("Wrong error: \(e)") }
        } catch { XCTFail("Unexpected: \(error)") }
    }
}

final class AppUserTests: XCTestCase {

    func test_initials_fullName()    { XCTAssertEqual(makeUser("John Doe").initials, "JD") }
    func test_initials_singleName()  { XCTAssertEqual(makeUser("Alice").initials, "A") }
    func test_initials_fromEmail()   { XCTAssertEqual(AppUser(uid:"u",email:"bob@x.com",displayName:nil,photoURL:nil,provider:.email).initials, "B") }
    func test_initials_bothNil()     { XCTAssertEqual(AppUser(uid:"u",email:nil,displayName:nil,photoURL:nil,provider:.apple).initials, "?") }
    func test_firstName_fullName()   { XCTAssertEqual(makeUser("Jane Smith").firstName, "Jane") }
    func test_firstName_nilName()    { XCTAssertEqual(AppUser(uid:"u",email:"t@t.com",displayName:nil,photoURL:nil,provider:.email).firstName, "") }

    func test_equality() {
        let a = makeUser("A", uid: "x")
        let b = makeUser("A", uid: "x")
        let c = makeUser("A", uid: "y")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    private func makeUser(_ name: String, uid: String = "u1") -> AppUser {
        AppUser(uid: uid, email: "a@a.com", displayName: name, photoURL: nil, provider: .apple)
    }
}

final class AuthErrorTests: XCTestCase {

    func test_allCases_haveDescriptions() {
        let errors: [AuthError] = [.signInCancelled, .noIDToken, .invalidCredential,
            .networkError, .userNotFound, .wrongPassword, .emailAlreadyInUse,
            .weakPassword, .unknown("msg")]
        for e in errors {
            XCTAssertFalse(e.errorDescription?.isEmpty ?? true, "Empty description for \(e)")
        }
    }

    func test_unknown_carriesMessage() {
        XCTAssertEqual(AuthError.unknown("Custom").errorDescription, "Custom")
    }
}

final class AuthProviderTests: XCTestCase {

    func test_rawValues() {
        XCTAssertEqual(AuthProvider.apple.rawValue,  "apple.com")
        XCTAssertEqual(AuthProvider.google.rawValue, "google.com")
        XCTAssertEqual(AuthProvider.email.rawValue,  "password")
    }

    func test_codableRoundTrip() throws {
        for p in [AuthProvider.apple, .google, .email] {
            let decoded = try JSONDecoder().decode(AuthProvider.self, from: try JSONEncoder().encode(p))
            XCTAssertEqual(decoded, p)
        }
    }
}

// ---- REMOVE EVERYTHING BELOW THIS LINE (old @Suite content) ----
private let _unusedSentinel = 0

    // MARK: - Initial State

    @Test("Service starts with no current user")
    func initialStateNoUser() {
        let service = AuthenticationService()
        #expect(service.currentUser == nil)
        #expect(service.isAuthenticated == false)
        #expect(service.isLoading == false)
        #expect(service.errorMessage == nil)
    }

    // MARK: - isAuthenticated

    @Test("isAuthenticated reflects currentUser presence")
    func isAuthenticatedMirrorsCurrentUser() {
        let service = AuthenticationService()
        #expect(service.isAuthenticated == false)

        service.currentUser = AppUser(
            uid: "u1",
            email: "user@example.com",
            displayName: "Test User",
            photoURL: nil,
            provider: .apple
        )
        #expect(service.isAuthenticated == true)
    }

    // MARK: - signOut

    @Test("signOut clears currentUser")
    func signOutClearsUser() {
        let service = AuthenticationService()
        service.currentUser = AppUser(
            uid: "u1",
            email: "hello@example.com",
            displayName: "Hello",
            photoURL: nil,
            provider: .apple
        )
        service.signOut()
        #expect(service.currentUser == nil)
        #expect(service.isAuthenticated == false)
    }

    @Test("signOut removes persisted user from UserDefaults")
    func signOutRemovesPersistedUser() throws {
        // Manually seed UserDefaults with a valid PersistedUser payload
        struct PersistedUser: Codable {
            let uid: String; let email: String?; let displayName: String?
            let photoURLString: String?; let provider: String
        }
        let persisted = PersistedUser(
            uid: "u99", email: "a@b.com", displayName: "A",
            photoURLString: nil, provider: "apple.com"
        )
        let data = try JSONEncoder().encode(persisted)
        UserDefaults.standard.set(data, forKey: "current_user")

        let service = AuthenticationService()
        service.signOut()

        #expect(UserDefaults.standard.data(forKey: "current_user") == nil)
    }

    // MARK: - restoreSession

    @Test("restoreSession populates currentUser when valid data exists in UserDefaults")
    func restoreSessionDecodesValidUser() throws {
        struct PersistedUser: Codable {
            let uid: String; let email: String?; let displayName: String?
            let photoURLString: String?; let provider: String
        }
        let persisted = PersistedUser(
            uid: "restored-uid",
            email: "restore@test.com",
            displayName: "Restored User",
            photoURLString: nil,
            provider: "apple.com"
        )
        let data = try JSONEncoder().encode(persisted)
        UserDefaults.standard.set(data, forKey: "current_user")
        defer { UserDefaults.standard.removeObject(forKey: "current_user") }

        let service = AuthenticationService()
        service.restoreSession()

        let user = try #require(service.currentUser)
        #expect(user.uid == "restored-uid")
        #expect(user.email == "restore@test.com")
        #expect(user.displayName == "Restored User")
        #expect(user.provider == .apple)
    }

    @Test("restoreSession leaves currentUser nil when UserDefaults has no data")
    func restoreSessionNoData() {
        UserDefaults.standard.removeObject(forKey: "current_user")
        let service = AuthenticationService()
        service.restoreSession()
        #expect(service.currentUser == nil)
    }

    @Test("restoreSession leaves currentUser nil when stored data is corrupt")
    func restoreSessionCorruptData() {
        UserDefaults.standard.set(Data([0xFF, 0xFE, 0x00]), forKey: "current_user")
        defer { UserDefaults.standard.removeObject(forKey: "current_user") }

        let service = AuthenticationService()
        service.restoreSession()
        #expect(service.currentUser == nil)
    }

    // MARK: - signInWithGoogle / signInWithEmail (stub behaviour)

    @Test("signInWithGoogle throws AuthError.unknown until Firebase is configured")
    func googleSignInThrowsWithoutFirebase() async {
        let service = AuthenticationService()
        do {
            _ = try await service.signInWithGoogle(presentingViewController: .init())
            Issue.record("Expected an error but got a result")
        } catch let error as AuthError {
            if case .unknown = error {
                // expected
            } else {
                Issue.record("Got wrong AuthError: \(error)")
            }
        } catch {
            Issue.record("Got unexpected error type: \(error)")
        }
    }

    @Test("signInWithEmail throws AuthError.unknown until Firebase is configured")
    func emailSignInThrowsWithoutFirebase() async {
        let service = AuthenticationService()
        do {
            _ = try await service.signInWithEmail(email: "test@test.com", password: "password")
            Issue.record("Expected an error but got a result")
        } catch let error as AuthError {
            if case .unknown = error {
                // expected
            } else {
                Issue.record("Got wrong AuthError: \(error)")
            }
        } catch {
            Issue.record("Got unexpected error type: \(error)")
        }
    }

    @Test("createAccount throws AuthError.unknown until Firebase is configured")
    func createAccountThrowsWithoutFirebase() async {
        let service = AuthenticationService()
        do {
            _ = try await service.createAccount(
                email: "new@test.com",
                password: "password",
                displayName: "New User"
            )
            Issue.record("Expected an error but got a result")
        } catch let error as AuthError {
            if case .unknown = error {
                // expected
            } else {
                Issue.record("Got wrong AuthError: \(error)")
            }
        } catch {
            Issue.record("Got unexpected error type: \(error)")
        }
    }

    @Test("sendPasswordReset throws AuthError.unknown until Firebase is configured")
    func passwordResetThrowsWithoutFirebase() async {
        let service = AuthenticationService()
        do {
            try await service.sendPasswordReset(email: "test@test.com")
            Issue.record("Expected an error but got a result")
        } catch let error as AuthError {
            if case .unknown = error {
                // expected
            } else {
                Issue.record("Got wrong AuthError: \(error)")
            }
        } catch {
            Issue.record("Got unexpected error type: \(error)")
        }
    }
}

// MARK: - AppUser Tests

@Suite("AppUser")
struct AppUserTests {

    @Test("initials are derived from first and last name")
    func initialsFromFullName() {
        let user = AppUser(
            uid: "u1",
            email: "john@doe.com",
            displayName: "John Doe",
            photoURL: nil,
            provider: .apple
        )
        #expect(user.initials == "JD")
    }

    @Test("initials fall back to single letter for single-word name")
    func initialsFromSingleName() {
        let user = AppUser(
            uid: "u2",
            email: nil,
            displayName: "Alice",
            photoURL: nil,
            provider: .google
        )
        #expect(user.initials == "A")
    }

    @Test("initials fall back to email first letter when no display name")
    func initialsFromEmail() {
        let user = AppUser(
            uid: "u3",
            email: "bob@example.com",
            displayName: nil,
            photoURL: nil,
            provider: .email
        )
        #expect(user.initials == "B")
    }

    @Test("initials return '?' when both displayName and email are nil")
    func initialsQuestionMark() {
        let user = AppUser(
            uid: "u4",
            email: nil,
            displayName: nil,
            photoURL: nil,
            provider: .apple
        )
        #expect(user.initials == "?")
    }

    @Test("firstName returns first word of displayName")
    func firstNameExtraction() {
        let user = AppUser(
            uid: "u5",
            email: nil,
            displayName: "Jane Smith",
            photoURL: nil,
            provider: .apple
        )
        #expect(user.firstName == "Jane")
    }

    @Test("firstName returns empty string when displayName is nil")
    func firstNameNilDisplayName() {
        let user = AppUser(
            uid: "u6",
            email: "test@test.com",
            displayName: nil,
            photoURL: nil,
            provider: .email
        )
        #expect(user.firstName == "")
    }

    @Test("AppUser equality works correctly")
    func appUserEquality() {
        let u1 = AppUser(uid: "abc", email: "a@a.com", displayName: "A", photoURL: nil, provider: .apple)
        let u2 = AppUser(uid: "abc", email: "a@a.com", displayName: "A", photoURL: nil, provider: .apple)
        let u3 = AppUser(uid: "xyz", email: "b@b.com", displayName: "B", photoURL: nil, provider: .google)
        #expect(u1 == u2)
        #expect(u1 != u3)
    }
}

// MARK: - AuthError Tests

@Suite("AuthError")
struct AuthErrorTests {

    @Test("All AuthError cases have non-empty error descriptions")
    func allCasesHaveDescriptions() {
        let errors: [AuthError] = [
            .signInCancelled,
            .noIDToken,
            .invalidCredential,
            .networkError,
            .userNotFound,
            .wrongPassword,
            .emailAlreadyInUse,
            .weakPassword,
            .unknown("Something went wrong")
        ]

        for error in errors {
            let desc = error.errorDescription
            #expect(desc != nil, "Expected description for \(error)")
            #expect(!(desc ?? "").isEmpty, "Expected non-empty description for \(error)")
        }
    }

    @Test("AuthError.unknown carries through the provided message")
    func unknownErrorCarriesMessage() {
        let message = "Custom error message"
        let error = AuthError.unknown(message)
        #expect(error.errorDescription == message)
    }
}

// MARK: - AuthProvider Tests

@Suite("AuthProvider")
struct AuthProviderTests {

    @Test("AuthProvider raw values are correct")
    func authProviderRawValues() {
        #expect(AuthProvider.apple.rawValue  == "apple.com")
        #expect(AuthProvider.google.rawValue == "google.com")
        #expect(AuthProvider.email.rawValue  == "password")
    }

    @Test("AuthProvider is Codable round-trip")
    func authProviderCodable() throws {
        for provider in [AuthProvider.apple, .google, .email] {
            let data    = try JSONEncoder().encode(provider)
            let decoded = try JSONDecoder().decode(AuthProvider.self, from: data)
            #expect(decoded == provider)
        }
    }
}
