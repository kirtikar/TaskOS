import XCTest
@testable import taskOS

// MARK: - AuthenticationService Tests

final class AuthenticationServiceTests: XCTestCase {

    // MARK: - Initial State

    func test_initialState_noCurrentUser() {
        let service = AuthenticationService()
        XCTAssertNil(service.currentUser)
        XCTAssertFalse(service.isAuthenticated)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.errorMessage)
    }

    // MARK: - isAuthenticated

    func test_isAuthenticated_reflectsCurrentUser() {
        let service = AuthenticationService()
        XCTAssertFalse(service.isAuthenticated)

        service.currentUser = AppUser(
            uid: "u1", email: "user@example.com",
            displayName: "Test User", photoURL: nil, provider: .apple
        )
        XCTAssertTrue(service.isAuthenticated)
    }

    // MARK: - signOut

    func test_signOut_clearsCurrentUser() {
        let service = AuthenticationService()
        service.currentUser = AppUser(
            uid: "u1", email: "hello@example.com",
            displayName: "Hello", photoURL: nil, provider: .apple
        )
        service.signOut()
        XCTAssertNil(service.currentUser)
        XCTAssertFalse(service.isAuthenticated)
    }

    func test_signOut_removesPersistedUserFromUserDefaults() throws {
        struct PersistedUser: Codable {
            let uid: String; let email: String?; let displayName: String?
            let photoURLString: String?; let provider: String
        }
        let data = try JSONEncoder().encode(
            PersistedUser(uid: "u99", email: "a@b.com", displayName: "A",
                          photoURLString: nil, provider: "apple.com")
        )
        UserDefaults.standard.set(data, forKey: "current_user")

        let service = AuthenticationService()
        service.signOut()

        XCTAssertNil(UserDefaults.standard.data(forKey: "current_user"))
    }

    // MARK: - restoreSession

    func test_restoreSession_decodesValidUser() throws {
        struct PersistedUser: Codable {
            let uid: String; let email: String?; let displayName: String?
            let photoURLString: String?; let provider: String
        }
        let data = try JSONEncoder().encode(
            PersistedUser(uid: "restored-uid", email: "restore@test.com",
                          displayName: "Restored User", photoURLString: nil,
                          provider: "apple.com")
        )
        UserDefaults.standard.set(data, forKey: "current_user")
        defer { UserDefaults.standard.removeObject(forKey: "current_user") }

        let service = AuthenticationService()
        service.restoreSession()

        let user = try XCTUnwrap(service.currentUser)
        XCTAssertEqual(user.uid, "restored-uid")
        XCTAssertEqual(user.email, "restore@test.com")
        XCTAssertEqual(user.displayName, "Restored User")
        XCTAssertEqual(user.provider, .apple)
    }

    func test_restoreSession_nilWhenNoData() {
        UserDefaults.standard.removeObject(forKey: "current_user")
        let service = AuthenticationService()
        service.restoreSession()
        XCTAssertNil(service.currentUser)
    }

    func test_restoreSession_nilWhenDataIsCorrupt() {
        UserDefaults.standard.set(Data([0xFF, 0xFE, 0x00]), forKey: "current_user")
        defer { UserDefaults.standard.removeObject(forKey: "current_user") }

        let service = AuthenticationService()
        service.restoreSession()
        XCTAssertNil(service.currentUser)
    }

    // MARK: - Stub error paths (pre-Firebase)

    func test_googleSignIn_throwsUnknownWithoutFirebase() async {
        let service = AuthenticationService()
        do {
            _ = try await service.signInWithGoogle(presentingViewController: .init())
            XCTFail("Expected AuthError.unknown to be thrown")
        } catch let error as AuthError {
            guard case .unknown = error else {
                return XCTFail("Expected .unknown, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_emailSignIn_throwsUnknownWithoutFirebase() async {
        let service = AuthenticationService()
        do {
            _ = try await service.signInWithEmail(email: "t@t.com", password: "pw")
            XCTFail("Expected AuthError.unknown to be thrown")
        } catch let error as AuthError {
            guard case .unknown = error else {
                return XCTFail("Expected .unknown, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_createAccount_throwsUnknownWithoutFirebase() async {
        let service = AuthenticationService()
        do {
            _ = try await service.createAccount(email: "n@t.com", password: "pw", displayName: "N")
            XCTFail("Expected AuthError.unknown to be thrown")
        } catch let error as AuthError {
            guard case .unknown = error else {
                return XCTFail("Expected .unknown, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_passwordReset_throwsUnknownWithoutFirebase() async {
        let service = AuthenticationService()
        do {
            try await service.sendPasswordReset(email: "t@t.com")
            XCTFail("Expected AuthError.unknown to be thrown")
        } catch let error as AuthError {
            guard case .unknown = error else {
                return XCTFail("Expected .unknown, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

// MARK: - AppUser Tests

final class AppUserTests: XCTestCase {

    func test_initials_fromFirstAndLastName() {
        let user = makeUser(displayName: "John Doe")
        XCTAssertEqual(user.initials, "JD")
    }

    func test_initials_fromSingleName() {
        let user = makeUser(displayName: "Alice")
        XCTAssertEqual(user.initials, "A")
    }

    func test_initials_fromEmailWhenNoDisplayName() {
        let user = AppUser(uid: "u", email: "bob@example.com",
                           displayName: nil, photoURL: nil, provider: .email)
        XCTAssertEqual(user.initials, "B")
    }

    func test_initials_questionMarkWhenBothNil() {
        let user = AppUser(uid: "u", email: nil,
                           displayName: nil, photoURL: nil, provider: .apple)
        XCTAssertEqual(user.initials, "?")
    }

    func test_firstName_returnsFirstWord() {
        let user = makeUser(displayName: "Jane Smith")
        XCTAssertEqual(user.firstName, "Jane")
    }

    func test_firstName_emptyWhenDisplayNameNil() {
        let user = AppUser(uid: "u", email: "t@t.com",
                           displayName: nil, photoURL: nil, provider: .email)
        XCTAssertEqual(user.firstName, "")
    }

    func test_equality_sameValues() {
        let u1 = makeUser(uid: "abc", displayName: "A")
        let u2 = makeUser(uid: "abc", displayName: "A")
        XCTAssertEqual(u1, u2)
    }

    func test_equality_differentUID() {
        let u1 = makeUser(uid: "abc", displayName: "A")
        let u2 = makeUser(uid: "xyz", displayName: "A")
        XCTAssertNotEqual(u1, u2)
    }

    // MARK: - Helpers
    private func makeUser(uid: String = "u1", displayName: String?) -> AppUser {
        AppUser(uid: uid, email: "a@a.com", displayName: displayName,
                photoURL: nil, provider: .apple)
    }
}

// MARK: - AuthError Tests

final class AuthErrorTests: XCTestCase {

    func test_allCases_haveNonEmptyDescriptions() {
        let errors: [AuthError] = [
            .signInCancelled, .noIDToken, .invalidCredential, .networkError,
            .userNotFound, .wrongPassword, .emailAlreadyInUse, .weakPassword,
            .unknown("Something went wrong")
        ]
        for error in errors {
            let desc = error.errorDescription
            XCTAssertNotNil(desc, "Expected description for \(error)")
            XCTAssertFalse(desc?.isEmpty ?? true, "Expected non-empty description for \(error)")
        }
    }

    func test_unknown_carriesProvidedMessage() {
        let message = "Custom error message"
        let error = AuthError.unknown(message)
        XCTAssertEqual(error.errorDescription, message)
    }
}

// MARK: - AuthProvider Tests

final class AuthProviderTests: XCTestCase {

    func test_rawValues() {
        XCTAssertEqual(AuthProvider.apple.rawValue,  "apple.com")
        XCTAssertEqual(AuthProvider.google.rawValue, "google.com")
        XCTAssertEqual(AuthProvider.email.rawValue,  "password")
    }

    func test_codableRoundTrip() throws {
        for provider in [AuthProvider.apple, .google, .email] {
            let data    = try JSONEncoder().encode(provider)
            let decoded = try JSONDecoder().decode(AuthProvider.self, from: data)
            XCTAssertEqual(decoded, provider)
        }
    }
}
