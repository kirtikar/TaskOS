import SwiftUI

// MARK: - Design Tokens
// Single source of truth for all visual decisions in TaskOS

// MARK: - DS (Design System namespace)

enum DS {

    // MARK: - Colors

    enum Colors {
        // Brand
        static let accent          = Color("AccentColor")   // defined in Assets
        static let accentSoft      = Color("AccentSoft")

        // Semantic backgrounds (auto light/dark)
        static let background      = Color(uiColor: .systemBackground)
        static let secondaryBG     = Color(uiColor: .secondarySystemBackground)
        static let tertiaryBG      = Color(uiColor: .tertiarySystemBackground)
        static let groupedBG       = Color(uiColor: .systemGroupedBackground)

        // Text
        static let label           = Color(uiColor: .label)
        static let secondaryLabel  = Color(uiColor: .secondaryLabel)
        static let tertiaryLabel   = Color(uiColor: .tertiaryLabel)
        static let placeholder     = Color(uiColor: .placeholderText)

        // Separators
        static let separator       = Color(uiColor: .separator)
        static let opaqueSeparator = Color(uiColor: .opaqueSeparator)

        // Priority
        static let priorityHigh    = Color.red
        static let priorityMedium  = Color.orange
        static let priorityLow     = Color.blue
        static let priorityNone    = Color(uiColor: .tertiaryLabel)

        // Status
        static let success         = Color.green
        static let warning         = Color.orange
        static let destructive     = Color.red
        static let overdue         = Color.red
    }

    // MARK: - Typography

    enum Typography {
        // Titles
        static let largeTitle  = Font.largeTitle.weight(.bold)
        static let title1      = Font.title.weight(.semibold)
        static let title2      = Font.title2.weight(.semibold)
        static let title3      = Font.title3.weight(.medium)

        // Body
        static let headline    = Font.headline
        static let body        = Font.body
        static let callout     = Font.callout
        static let subheadline = Font.subheadline
        static let footnote    = Font.footnote.weight(.medium)
        static let caption1    = Font.caption
        static let caption2    = Font.caption2
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat  = 8
        static let sm: CGFloat  = 12
        static let md: CGFloat  = 16
        static let lg: CGFloat  = 20
        static let xl: CGFloat  = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Radius

    enum Radius {
        static let xs: CGFloat  = 6
        static let sm: CGFloat  = 10
        static let md: CGFloat  = 14
        static let lg: CGFloat  = 20
        static let pill: CGFloat = 100
    }

    // MARK: - Shadow

    enum Shadow {
        static let soft  = ShadowStyle(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        static let card  = ShadowStyle(color: .black.opacity(0.10), radius: 16, x: 0, y: 4)
        static let modal = ShadowStyle(color: .black.opacity(0.18), radius: 30, x: 0, y: 8)
    }

    // MARK: - Animation

    enum Animation {
        static let quick    = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let standard = SwiftUI.Animation.spring(response: 0.45, dampingFraction: 0.8)
        static let bouncy   = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        static let smooth   = SwiftUI.Animation.easeInOut(duration: 0.25)
    }
}

// MARK: - ShadowStyle

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Priority Color Helpers

extension Priority {
    var color: Color {
        switch self {
        case .high:   return DS.Colors.priorityHigh
        case .medium: return DS.Colors.priorityMedium
        case .low:    return DS.Colors.priorityLow
        case .none:   return DS.Colors.priorityNone
        }
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DS.Colors.secondaryBG)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
            .shadow(
                color: DS.Colors.shadow.opacity(0.08),
                radius: 8, x: 0, y: 2
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

private extension DS.Colors {
    static let shadow = Color.black
}
