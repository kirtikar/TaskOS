import XCTest
import SwiftUI
@testable import TaskOS

final class ThemeTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "app_theme")
        UserDefaults.standard.removeObject(forKey: "accent_color")
        UserDefaults.standard.removeObject(forKey: "large_titles")
    }

    func testAppThemeRawValues() {
        XCTAssertEqual(AppTheme.system.rawValue, "System")
        XCTAssertEqual(AppTheme.light.rawValue,  "Light")
        XCTAssertEqual(AppTheme.dark.rawValue,   "Dark")
    }

    func testAppThemeColorSchemes() {
        XCTAssertNil(AppTheme.system.colorScheme)
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
        XCTAssertEqual(AppTheme.dark.colorScheme,  .dark)
    }

    func testAppThemeThreeCasesDistinctSymbols() {
        XCTAssertEqual(AppTheme.allCases.count, 3)
        XCTAssertEqual(Set(AppTheme.allCases.map(\.sfSymbol)).count, 3)
    }

    func testPersistsTheme() {
        ThemeManager.shared.theme = .dark
        XCTAssertEqual(UserDefaults.standard.string(forKey: "app_theme"), "Dark")
    }

    func testPersistsLargeTitles() {
        ThemeManager.shared.preferLargeTitles = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "large_titles"))
        ThemeManager.shared.preferLargeTitles = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "large_titles"))
    }

    func testPersistsAccentColor() {
        ThemeManager.shared.accentColorName = "Purple"
        XCTAssertEqual(UserDefaults.standard.string(forKey: "accent_color"), "Purple")
    }

    func testAccentOptionEightCases() {
        XCTAssertEqual(AccentOption.allCases.count, 8)
    }

    func testAccentOptionRawValues() {
        let expected = ["Blue", "Indigo", "Purple", "Pink", "Red", "Orange", "Teal", "Green"]
        XCTAssertEqual(AccentOption.allCases.map(\.rawValue), expected)
    }

    func testUserDefaultsContains() {
        let key = "test_\(UUID().uuidString)"
        defer { UserDefaults.standard.removeObject(forKey: key) }
        XCTAssertFalse(UserDefaults.standard.contains(key))
        UserDefaults.standard.set("v", forKey: key)
        XCTAssertTrue(UserDefaults.standard.contains(key))
    }

    func testSpacingAscending() {
        XCTAssertLessThan(DS.Spacing.xxs, DS.Spacing.xs)
        XCTAssertLessThan(DS.Spacing.xs,  DS.Spacing.sm)
        XCTAssertLessThan(DS.Spacing.sm,  DS.Spacing.md)
        XCTAssertLessThan(DS.Spacing.md,  DS.Spacing.lg)
        XCTAssertLessThan(DS.Spacing.lg,  DS.Spacing.xl)
        XCTAssertLessThan(DS.Spacing.xl,  DS.Spacing.xxl)
        XCTAssertLessThan(DS.Spacing.xxl, DS.Spacing.xxxl)
    }

    func testRadiusAscending() {
        XCTAssertLessThan(DS.Radius.xs, DS.Radius.sm)
        XCTAssertLessThan(DS.Radius.sm, DS.Radius.md)
        XCTAssertLessThan(DS.Radius.md, DS.Radius.lg)
        XCTAssertLessThan(DS.Radius.lg, DS.Radius.pill)
    }

    func testProjectColorTenCases() { XCTAssertEqual(ProjectColor.allCases.count, 10) }
    func testProjectColorLowercaseRaw() {
        for c in ProjectColor.allCases { XCTAssertEqual(c.rawValue, c.rawValue.lowercased()) }
    }

    func testProjectIconSfSymbol() {
        for icon in ProjectIcon.allCases { XCTAssertEqual(icon.sfSymbol, icon.rawValue) }
    }

    func testColorHex_valid()   { XCTAssertNotNil(Color(hex: "#007AFF")) }
    func testColorHex_noHash()  { XCTAssertNotNil(Color(hex: "007AFF")) }
    func testColorHex_invalid() { XCTAssertNil(Color(hex: "ZZZZZZ")) }
    func testColorHex_empty()   { XCTAssertNil(Color(hex: "")) }
}
