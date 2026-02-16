import SwiftUI

// MARK: - TagChip

enum TagChipSize {
    case small, medium

    var font: Font {
        switch self {
        case .small:  return DS.Typography.caption2
        case .medium: return DS.Typography.caption1
        }
    }

    var padding: EdgeInsets {
        switch self {
        case .small:  return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
        case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        }
    }
}

struct TagChip: View {
    let tag: Tag
    var size: TagChipSize = .medium
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(tag.name)
                .font(size.font)
                .foregroundStyle(tag.color)

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(tag.color.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(size.padding)
        .background(tag.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - PriorityBadge

struct PriorityBadge: View {
    let priority: Priority
    var showLabel: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priority.sfSymbol)
                .font(.caption.weight(.bold))
            if showLabel {
                Text(priority.label)
                    .font(DS.Typography.footnote)
            }
        }
        .foregroundStyle(priority.color)
        .padding(.horizontal, DS.Spacing.xs)
        .padding(.vertical, DS.Spacing.xxs)
        .background(priority.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String
    var count: Int? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"

    var body: some View {
        HStack {
            HStack(spacing: DS.Spacing.xs) {
                Text(title)
                    .font(DS.Typography.footnote)
                    .foregroundStyle(DS.Colors.secondaryLabel)
                    .textCase(.uppercase)
                    .tracking(0.5)

                if let count, count > 0 {
                    Text("\(count)")
                        .font(DS.Typography.caption2)
                        .foregroundStyle(DS.Colors.tertiaryLabel)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DS.Colors.tertiaryBG)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            if let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(DS.Typography.footnote)
                        .foregroundStyle(DS.Colors.accent)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.sm)
        .padding(.bottom, DS.Spacing.xxs)
    }
}

// MARK: - EmptyState

struct EmptyStateView: View {
    let sfSymbol: String
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: sfSymbol)
                .font(.system(size: 52))
                .foregroundStyle(DS.Colors.tertiaryLabel)
                .padding(.bottom, DS.Spacing.xs)

            Text(title)
                .font(DS.Typography.title3)
                .foregroundStyle(DS.Colors.label)

            Text(message)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xxl)

            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(DS.Typography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DS.Spacing.xl)
                        .padding(.vertical, DS.Spacing.sm)
                        .background(DS.Colors.accent)
                        .clipShape(Capsule())
                }
                .padding(.top, DS.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xxxl)
    }
}
