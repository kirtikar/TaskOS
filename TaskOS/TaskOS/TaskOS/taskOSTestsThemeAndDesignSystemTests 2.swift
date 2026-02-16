import XCTest
import SwiftUI
@testable import taskOS

// MARK: - ThemeManager Tests

final class ThemeManagerTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "app_theme")
        UserDefaults.standard.removeObject(forKey: "accent_color")
        UserDefaults.standard.removeObject(forKey: "large_titles")
    }

    // MARK: - AppTheme

    func test_appTheme_rawValues() {
        XCTAssertEqual(AppTheme.system.rawValue, "System")
        XCTAssertEqual(AppTheme.light.rawValue,  "Light")
        XCTAssertEqual(AppTheme.dark.rawValue,   "Dark")
    }

    func test_appTheme_colorSchemes() {
        XCTAssertNil(AppTheme.system.colorScheme)
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
        XCTAssertEqual(AppTheme.dark.colorScheme,  .dark)
    }

    func test_appTheme_sfSymbolsAreNonEmpty() {
        for theme in AppTheme.allCases {
            XCTAssertFalse(theme.sfSymbol.isEmpty, "sfSymbol should not be empty for \(theme)")
        }
    }

    func test_appTheme_threeDistinctCases() {
        XCTAssertEqual(AppTheme.allCases.count, 3)
        let symbols = AppTheme.allCases.map(\.sfSymbol)
        XCTAssertEqual(Set(symbols).count, 3, "All sfSymbols should be unique")
    }

    // MARK: - ThemeManager persistence

    func test_themeManager_persistsTheme() {
        ThemeManager.shared.theme = .dark
        XCTAssertEqual(UserDefaults.standard.string(forKey: "app_theme"), AppTheme.dark.rawValue)
    }

    func test_themeManager_persistsLargeTitles() {
        ThemeManager.shared.preferLargeTitles = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "large_titles"))
        ThemeManager.shared.preferLargeTitles = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "large_titles"))
    }

    func test_themeManager_persistsAccentColor() {
        ThemeManager.shared.accentColorName = "Purple"
        XCTAssertEqual(UserDefaults.standard.string(forKey: "accent_color"), "Purple")
    }

    // MARK: - AccentOption

    func test_accentOption_eightCases() {
        XCTAssertEqual(AccentOption.allCases.count, 8)
    }

    func test_accentOption_rawValues() {
        let expected = ["Blue", "Indigo", "Purple", "Pink", "Red", "Orange", "Teal", "Green"]
        XCTAssertEqual(AccentOption.allCases.map(\.rawValue), expected)
    }

    // MARK: - UserDefaults.contains helper

    func test_userDefaultsContains_trueForExistingKey() {
        let key = "test_key_\(UUID().uuidString)"
        defer { UserDefaults.standard.removeObject(forKey: key) }
        UserDefaults.standard.set("value", forKey: key)
        XCTAssertTrue(UserDefaults.standard.contains(key))
    }

    func test_userDefaultsContains_falseForMissingKey() {
        XCTAssertFalse(UserDefaults.standard.contains("definitely_not_set_\(UUID().uuidString)"))
    }
}

// MARK: - DesignSystem Tests

final class DesignSystemTests: XCTestCase {

    func test_spacing_ascendingOrder() {
        XCTAssertLessThan(DS.Spacing.xxs, DS.Spacing.xs)
        XCTAssertLessThan(DS.Spacing.xs,  DS.Spacing.sm)
        XCTAssertLessThan(DS.Spacing.sm,  DS.Spacing.md)
        XCTAssertLessThan(DS.Spacing.md,  DS.Spacing.lg)
        XCTAssertLessThan(DS.Spacing.lg,  DS.Spacing.xl)
        XCTAssertLessThan(DS.Spacing.xl,  DS.Spacing.xxl)
        XCTAssertLessThan(DS.Spacing.xxl, DS.Spacing.xxxl)
    }

    func test_spacing_allPositive() {
        let values: [CGFloat] = [
            DS.Spacing.xxs, DS.Spacing.xs, DS.Spacing.sm, DS.Spacing.md,
            DS.Spacing.lg,  DS.Spacing.xl, DS.Spacing.xxl, DS.Spacing.xxxl
        ]
        values.forEach { XCTAssertGreaterThan($0, 0) }
    }

    func test_radius_ascendingOrder() {
        XCTAssertLessThan(DS.Radius.xs, DS.Radius.sm)
        XCTAssertLessThan(DS.Radius.sm, DS.Radius.md)
        XCTAssertLessThan(DS.Radius.md, DS.Radius.lg)
        XCTAssertLessThan(DS.Radius.lg, DS.Radius.pill)
    }

    func test_priorityColor_doesNotCrashForAllCases() {
        Priority.allCases.forEach { _ = $0.color }
    }
}

// MARK: - Project Enum Tests

final class ProjectEnumTests: XCTestCase {

    func test_projectColor_tenCases() {
        XCTAssertEqual(ProjectColor.allCases.count, 10)
    }

    func test_projectColor_rawValuesAreLowercase() {
        for color in ProjectColor.allCases {
            XCTAssertEqual(color.rawValue, color.rawValue.lowercased())
        }
    }

    func test_projectIcon_sfSymbolEqualsRawValue() {
        for icon in ProjectIcon.allCases {
            XCTAssertEqual(icon.sfSymbol, icon.rawValue)
        }
    }

    func test_projectIcon_atLeastTenCases() {
        XCTAssertGreaterThanOrEqual(ProjectIcon.allCases.count, 10)
    }
}

// MARK: - Color Hex Extension Tests

final class ColorHexExtensionTests: XCTestCase {

    func test_colorFromHex_validSixDigitWithHash() {
        XCTAssertNotNil(Color(hex: "#007AFF"))
    }

    func test_colorFromHex_validSixDigitWithoutHash() {
        XCTAssertNotNil(Color(hex: "007AFF"))
    }

    func test_colorFromHex_invalidStringReturnsNil() {
        XCTAssertNil(Color(hex: "ZZZZZZ"))
    }

    func test_colorFromHex_emptyStringReturnsNil() {
        XCTAssertNil(Color(hex: ""))
    }

    func test_colorFromHex_redColorDoesNotReturnNil() {
        XCTAssertNotNil(Color(hex: "#FF0000"))
    }
}
