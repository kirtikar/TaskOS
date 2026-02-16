import Foundation
import AuthenticationServices
import CryptoKit
import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// AuthenticationService
//
// Handles:
//   • Sign in with Apple  (native, no SDK)
//   • Sign in with Google (via Firebase Auth — requires FirebaseAuth SPM package)
//   • Email / Password    (via Firebase Auth)
//
// Firebase setup:
//   1. Add firebase-ios-sdk package in Xcode
//      File → Add Package Dependencies → https://github.com/firebase/firebase-ios-sdk
//      Products to add: FirebaseAuth
//   2. Download GoogleService-Info.plist from Firebase Console → add to project
//   3. In AppDelegate / TaskOSApp: FirebaseApp.configure()
// ─────────────────────────────────────────────────────────────────────────────

// MARK: - AuthenticationService

@Observable
final class AuthenticationService: NSObject {

    // MARK: State
    var currentUser: AppUser? = nil
    var isLoading     = false
    var errorMessage: String? = nil

    var isAuthenticated: Bool { currentUser != nil }

    // Apple Sign-In nonce (PKCE)
    private var currentNonce: String?
    private var appleSignInContinuation: CheckedContinuation<AppUser, Error>?

    // MARK: - Sign In with Apple

    func signInWithApple() async throws -> AppUser {
        let nonce = randomNonce()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        return try await withCheckedThrowingContinuation { continuation in
            self.appleSignInContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - Sign In with Google
    // Requires: FirebaseAuth + GoogleSignIn SDK
    // Uncomment after adding Firebase packages

    func signInWithGoogle(presentingViewController: UIViewController) async throws -> AppUser {
        // ── Uncomment after adding firebase-ios-sdk + GoogleSignIn SPM packages ──
        //
        // import FirebaseAuth
        // import GoogleSignIn
        //
        // guard let clientID = FirebaseApp.app()?.options.clientID else {
        //     throw AuthError.invalidCredential
        // }
        // let config = GIDConfiguration(clientID: clientID)
        // GIDSignIn.sharedInstance.configuration = config
        //
        // let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        // guard let idToken = result.user.idToken?.tokenString else {
        //     throw AuthError.noIDToken
        // }
        // let credential = GoogleAuthProvider.credential(
        //     withIDToken: idToken,
        //     accessToken: result.user.accessToken.tokenString
        // )
        // let authResult = try await Auth.auth().signIn(with: credential)
        // let user = authResult.user
        // let appUser = AppUser(
        //     uid: user.uid,
        //     email: user.email,
        //     displayName: user.displayName,
        //     photoURL: user.photoURL,
        //     provider: .google
        // )
        // currentUser = appUser
        // persistUser(appUser)
        // return appUser
        //
        // ─────────────────────────────────────────────────────────────────────

        // Placeholder until Firebase packages are added:
        throw AuthError.unknown("Add firebase-ios-sdk package to enable Google Sign-In. See README.")
    }

    // MARK: - Email / Password Sign In

    func signInWithEmail(email: String, password: String) async throws -> AppUser {
        isLoading = true
        defer { isLoading = false }

        // ── Uncomment after adding firebase-ios-sdk ──
        //
        // import FirebaseAuth
        //
        // do {
        //     let result = try await Auth.auth().signIn(withEmail: email, password: password)
        //     let user = result.user
        //     let appUser = AppUser(
        //         uid: user.uid,
        //         email: user.email,
        //         displayName: user.displayName,
        //         photoURL: user.photoURL,
        //         provider: .email
        //     )
        //     currentUser = appUser
        //     persistUser(appUser)
        //     return appUser
        // } catch let error as NSError {
        //     throw mapFirebaseError(error)
        // }
        //
        // ─────────────────────────────────────────────

        throw AuthError.unknown("Add firebase-ios-sdk to enable Email Sign-In.")
    }

    // MARK: - Email / Password Sign Up

    func createAccount(email: String, password: String, displayName: String) async throws -> AppUser {
        isLoading = true
        defer { isLoading = false }

        // ── Uncomment after adding firebase-ios-sdk ──
        //
        // let result = try await Auth.auth().createUser(withEmail: email, password: password)
        // let changeRequest = result.user.createProfileChangeRequest()
        // changeRequest.displayName = displayName
        // try await changeRequest.commitChanges()
        // let appUser = AppUser(
        //     uid: result.user.uid,
        //     email: email,
        //     displayName: displayName,
        //     photoURL: nil,
        //     provider: .email
        // )
        // currentUser = appUser
        // persistUser(appUser)
        // return appUser
        //
        // ─────────────────────────────────────────────

        throw AuthError.unknown("Add firebase-ios-sdk to enable account creation.")
    }

    // MARK: - Password Reset

    func sendPasswordReset(email: String) async throws {
        // try await Auth.auth().sendPasswordReset(withEmail: email)
        throw AuthError.unknown("Add firebase-ios-sdk to enable password reset.")
    }

    // MARK: - Sign Out

    func signOut() {
        // try? Auth.auth().signOut()
        currentUser = nil
        clearPersistedUser()
    }

    // MARK: - Restore Session

    func restoreSession() {
        // On app launch, check if a user session exists
        // With Firebase: Auth.auth().addStateDidChangeListener { ... }
        // Without Firebase: use Keychain-persisted user
        if let userData = UserDefaults.standard.data(forKey: "current_user"),
           let decoded = try? JSONDecoder().decode(PersistedUser.self, from: userData) {
            currentUser = AppUser(
                uid: decoded.uid,
                email: decoded.email,
                displayName: decoded.displayName,
                photoURL: decoded.photoURLString.flatMap(URL.init),
                provider: AuthProvider(rawValue: decoded.provider) ?? .apple
            )
        }
    }

    // MARK: - Persistence (lightweight — use Keychain in production)

    private func persistUser(_ user: AppUser) {
        let persisted = PersistedUser(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoURLString: user.photoURL?.absoluteString,
            provider: user.provider.rawValue
        )
        if let encoded = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(encoded, forKey: "current_user")
        }
    }

    private func clearPersistedUser() {
        UserDefaults.standard.removeObject(forKey: "current_user")
    }

    // MARK: - Firebase Error Mapping

    private func mapFirebaseError(_ error: NSError) -> AuthError {
        // Firebase Auth error codes
        switch error.code {
        case 17008: return .invalidCredential
        case 17009: return .wrongPassword
        case 17011: return .userNotFound
        case 17007: return .emailAlreadyInUse
        case 17026: return .weakPassword
        case 17020: return .networkError
        default:    return .unknown(error.localizedDescription)
        }
    }

    // MARK: - Nonce Helpers (Apple Sign In / PKCE)

    private func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        precondition(errorCode == errSecSuccess, "Unable to generate nonce")
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationService: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8)
        else {
            appleSignInContinuation?.resume(throwing: AuthError.noIDToken)
            return
        }

        _ = identityToken  // use with Firebase: AppleAuthProvider.credential(...)
        _ = nonce

        // Build display name from Apple credential (only provided on first sign-in)
        let fullName = [
            credential.fullName?.givenName,
            credential.fullName?.familyName
        ].compactMap { $0 }.joined(separator: " ")

        let userID = credential.user

        // ── With Firebase Auth ──────────────────────────────────────────────
        // let appleCredential = OAuthProvider.appleCredential(
        //     withIDToken: identityToken,
        //     rawNonce: nonce,
        //     fullName: credential.fullName
        // )
        // Task {
        //     do {
        //         let result = try await Auth.auth().signIn(with: appleCredential)
        //         let appUser = AppUser(uid: result.user.uid, ...)
        //         currentUser = appUser
        //         appleSignInContinuation?.resume(returning: appUser)
        //     } catch {
        //         appleSignInContinuation?.resume(throwing: error)
        //     }
        // }
        // ────────────────────────────────────────────────────────────────────

        // Without Firebase (local only):
        let appUser = AppUser(
            uid: userID,
            email: credential.email,
            displayName: fullName.isEmpty ? credential.email : fullName,
            photoURL: nil,
            provider: .apple
        )
        currentUser = appUser
        persistUser(appUser)
        appleSignInContinuation?.resume(returning: appUser)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let authError = error as? ASAuthorizationError,
           authError.code == .canceled {
            appleSignInContinuation?.resume(throwing: AuthError.signInCancelled)
        } else {
            appleSignInContinuation?.resume(throwing: AuthError.unknown(error.localizedDescription))
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow ?? UIWindow()
    }
}

// MARK: - PersistedUser (Codable for UserDefaults)

private struct PersistedUser: Codable {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURLString: String?
    let provider: String
}
