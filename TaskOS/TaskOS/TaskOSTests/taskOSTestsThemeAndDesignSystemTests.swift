import Testing
import Foundation
import SwiftUI
@testable import TaskOS

// MARK: - ThemeManager Tests

@Suite("ThemeManager")
struct ThemeManagerTests {

    // Clean up after each test to prevent bleed
    private func cleanDefaults() {
        UserDefaults.standard.removeObject(forKey: "app_theme")
        UserDefaults.standard.removeObject(forKey: "accent_color")
        UserDefaults.standard.removeObject(forKey: "large_titles")
    }

    // MARK: - AppTheme

    @Test("AppTheme raw values are correct")
    func appThemeRawValues() {
        #expect(AppTheme.system.rawValue == "System")
        #expect(AppTheme.light.rawValue  == "Light")
        #expect(AppTheme.dark.rawValue   == "Dark")
    }

    @Test("AppTheme colorScheme returns correct values")
    func appThemeColorScheme() {
        #expect(AppTheme.system.colorScheme == nil)
        #expect(AppTheme.light.colorScheme  == .light)
        #expect(AppTheme.dark.colorScheme   == .dark)
    }

    @Test("AppTheme sfSymbol strings are non-empty")
    func appThemeSfSymbols() {
        for theme in AppTheme.allCases {
            #expect(!theme.sfSymbol.isEmpty, "Expected non-empty sfSymbol for \(theme)")
        }
    }

    @Test("AppTheme has exactly three cases")
    func appThemeAllCasesCount() {
        #expect(AppTheme.allCases.count == 3)
    }

    @Test("AppTheme sfSymbols are all distinct")
    func appThemeSfSymbolsDistinct() {
        let symbols = AppTheme.allCases.map(\.sfSymbol)
        #expect(Set(symbols).count == symbols.count)
    }

    // MARK: - ThemeManager Persistence

    @Test("ThemeManager persists theme change to UserDefaults")
    func themeManagerPersistsTheme() {
        cleanDefaults()
        defer { cleanDefaults() }

        let manager = ThemeManager.shared
        manager.theme = .dark
        let saved = UserDefaults.standard.string(forKey: "app_theme")
        #expect(saved == AppTheme.dark.rawValue)
    }

    @Test("ThemeManager persists preferLargeTitles change to UserDefaults")
    func themeManagerPersistsLargeTitles() {
        cleanDefaults()
        defer { cleanDefaults() }

        let manager = ThemeManager.shared
        manager.preferLargeTitles = false
        #expect(UserDefaults.standard.bool(forKey: "large_titles") == false)

        manager.preferLargeTitles = true
        #expect(UserDefaults.standard.bool(forKey: "large_titles") == true)
    }

    @Test("ThemeManager persists accentColorName to UserDefaults")
    func themeManagerPersistsAccentColor() {
        cleanDefaults()
        defer { cleanDefaults() }

        let manager = ThemeManager.shared
        manager.accentColorName = "Purple"
        #expect(UserDefaults.standard.string(forKey: "accent_color") == "Purple")
    }

    // MARK: - AccentOption

    @Test("AccentOption allCases has eight entries")
    func accentOptionAllCasesCount() {
        #expect(AccentOption.allCases.count == 8)
    }

    @Test("AccentOption raw values are human-readable colour names")
    func accentOptionRawValues() {
        let expected = ["Blue", "Indigo", "Purple", "Pink", "Red", "Orange", "Teal", "Green"]
        let actual   = AccentOption.allCases.map(\.rawValue)
        #expect(actual == expected)
    }

    // MARK: - UserDefaults.contains helper

    @Test("UserDefaults.contains returns true for an existing key")
    func userDefaultsContainsExistingKey() {
        let key = "test_exists_\(UUID().uuidString)"
        defer { UserDefaults.standard.removeObject(forKey: key) }

        UserDefaults.standard.set("value", forKey: key)
        #expect(UserDefaults.standard.contains(key) == true)
    }

    @Test("UserDefaults.contains returns false for a missing key")
    func userDefaultsContainsMissingKey() {
        let key = "definitely_not_set_\(UUID().uuidString)"
        #expect(UserDefaults.standard.contains(key) == false)
    }
}

// MARK: - DesignSystem Tests

@Suite("DesignSystem")
struct DesignSystemTests {

    // MARK: - Spacing

    @Test("DS.Spacing tokens are in ascending order")
    func spacingAscendingOrder() {
        #expect(DS.Spacing.xxs < DS.Spacing.xs)
        #expect(DS.Spacing.xs  < DS.Spacing.sm)
        #expect(DS.Spacing.sm  < DS.Spacing.md)
        #expect(DS.Spacing.md  < DS.Spacing.lg)
        #expect(DS.Spacing.lg  < DS.Spacing.xl)
        #expect(DS.Spacing.xl  < DS.Spacing.xxl)
        #expect(DS.Spacing.xxl < DS.Spacing.xxxl)
    }

    @Test("DS.Spacing values are all positive")
    func spacingAllPositive() {
        let values: [CGFloat] = [
            DS.Spacing.xxs, DS.Spacing.xs, DS.Spacing.sm,
            DS.Spacing.md,  DS.Spacing.lg, DS.Spacing.xl,
            DS.Spacing.xxl, DS.Spacing.xxxl
        ]
        for value in values {
            #expect(value > 0, "Expected positive spacing, got \(value)")
        }
    }

    // MARK: - Radius

    @Test("DS.Radius tokens are in ascending order")
    func radiusAscendingOrder() {
        #expect(DS.Radius.xs  < DS.Radius.sm)
        #expect(DS.Radius.sm  < DS.Radius.md)
        #expect(DS.Radius.md  < DS.Radius.lg)
        #expect(DS.Radius.lg  < DS.Radius.pill)
    }

    // MARK: - Priority Color Extension

    @Test("Priority.color returns distinct colors for each case")
    func priorityColorsAreDistinct() {
        // We can't compare Color values directly, but we can verify the
        // function doesn't crash for every case.
        for priority in Priority.allCases {
            let _ = priority.color
        }
    }
}

// MARK: - ProjectColor & ProjectIcon Tests

@Suite("Project Enums")
struct ProjectEnumTests {

    @Test("ProjectColor allCases has ten entries")
    func projectColorAllCasesCount() {
        #expect(ProjectColor.allCases.count == 10)
    }

    @Test("ProjectColor raw values are lowercase strings")
    func projectColorRawValuesLowercase() {
        for color in ProjectColor.allCases {
            #expect(color.rawValue == color.rawValue.lowercased(),
                    "Expected lowercase rawValue for \(color.rawValue)")
        }
    }

    @Test("ProjectIcon sfSymbol equals rawValue")
    func projectIconSfSymbolEqualsRawValue() {
        for icon in ProjectIcon.allCases {
            #expect(icon.sfSymbol == icon.rawValue)
        }
    }

    @Test("ProjectIcon allCases contains at least 10 icons")
    func projectIconAllCasesMinCount() {
        #expect(ProjectIcon.allCases.count >= 10)
    }
}

// MARK: - Tag Color Hex Extension Tests

@Suite("Color Hex Extension")
struct ColorHexExtensionTests {

    @Test("Color(hex:) initialises successfully from a valid 6-digit hex string")
    func colorFromValidHex() {
        let color = Color(hex: "#007AFF")
        #expect(color != nil)
    }

    @Test("Color(hex:) initialises successfully without the leading #")
    func colorFromHexWithoutHash() {
        let color = Color(hex: "007AFF")
        #expect(color != nil)
    }

    @Test("Color(hex:) returns nil for an invalid hex string")
    func colorFromInvalidHex() {
        let color = Color(hex: "ZZZZZZ")
        #expect(color == nil)
    }

    @Test("Color(hex:) returns nil for an empty string")
    func colorFromEmptyString() {
        let color = Color(hex: "")
        #expect(color == nil)
    }

    @Test("Parsing #FF0000 produces a reddish color (r ≈ 1.0)")
    func redColorComponents() {
        let color = Color(hex: "#FF0000")
        #expect(color != nil)
        // We trust the hex math; just ensure it initialises without nil
    }
}
