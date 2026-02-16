import SwiftUI

// MARK: - Theme

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light  = "Light"
    case dark   = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var sfSymbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - ThemeManager

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var theme: AppTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
        }
    }

    var accentColorName: String {
        didSet {
            UserDefaults.standard.set(accentColorName, forKey: "accent_color")
        }
    }

    var preferLargeTitles: Bool {
        didSet {
            UserDefaults.standard.set(preferLargeTitles, forKey: "large_titles")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_theme") ?? AppTheme.system.rawValue
        self.theme = AppTheme(rawValue: saved) ?? .system
        self.accentColorName = UserDefaults.standard.string(forKey: "accent_color") ?? "AccentColor"
        self.preferLargeTitles = UserDefaults.standard.bool(forKey: "large_titles")
        if !UserDefaults.standard.contains("large_titles") {
            self.preferLargeTitles = true
        }
    }
}

// MARK: - UserDefaults helper

extension UserDefaults {
    func contains(_ key: String) -> Bool {
        object(forKey: key) != nil
    }
}

// MARK: - AccentColor Options

enum AccentOption: String, CaseIterable {
    case blue   = "Blue"
    case indigo = "Indigo"
    case purple = "Purple"
    case pink   = "Pink"
    case red    = "Red"
    case orange = "Orange"
    case teal   = "Teal"
    case green  = "Green"

    var color: Color {
        switch self {
        case .blue:   return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink:   return .pink
        case .red:    return .red
        case .orange: return .orange
        case .teal:   return .teal
        case .green:  return .green
        }
    }
}
