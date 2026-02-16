import Foundation

// MARK: - AppUser
// Represents the authenticated user in the app.
// Decoupled from any auth provider — works with Apple, Google, or Email.

struct AppUser: Equatable {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let provider: AuthProvider

    var initials: String {
        let name = displayName ?? email ?? "?"
        return name
            .components(separatedBy: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }

    var firstName: String {
        displayName?.components(separatedBy: " ").first ?? ""
    }
}

// MARK: - AuthProvider

enum AuthProvider: String, Codable {
    case apple  = "apple.com"
    case google = "google.com"
    case email  = "password"
}

// MARK: - AuthError

enum AuthError: LocalizedError {
    case signInCancelled
    case noIDToken
    case invalidCredential
    case networkError
    case userNotFound
    case wrongPassword
    case emailAlreadyInUse
    case weakPassword
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .signInCancelled:    return "Sign-in was cancelled."
        case .noIDToken:          return "Could not retrieve identity token."
        case .invalidCredential:  return "Invalid credentials. Please try again."
        case .networkError:       return "Network error. Check your connection."
        case .userNotFound:       return "No account found with this email."
        case .wrongPassword:      return "Incorrect password."
        case .emailAlreadyInUse:  return "An account already exists with this email."
        case .weakPassword:       return "Password must be at least 6 characters."
        case .unknown(let msg):   return msg
        }
    }
}
