import SwiftUI

// MARK: - App Icon Preview
// Run this preview to see the icon at actual size.
// To export: screenshot at 1024×1024 and crop to the rounded-square mask.
//
// SPEC:
//   Background: teal (#00B7C3) → indigo (#5B3DEB) diagonal gradient
//   Symbol:     SF Symbol "checkmark.circle.fill" white, size 460pt centred
//   Corner:     113pt (Apple's standard icon radius at 1024pt ≈ 22.5%)
//   Shadow:     inner glow, white 8% opacity, 280pt circle offset top-left

struct AppIconPreview: View {
    var size: CGFloat = 180

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.00, green: 0.72, blue: 0.76),  // teal
                    Color(red: 0.36, green: 0.24, blue: 0.92)   // indigo
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle highlight
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: size * 1.1, height: size * 1.1)
                .offset(x: -size * 0.2, y: -size * 0.25)

            // Main checkmark
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.56)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.18), radius: size * 0.06, x: 0, y: size * 0.03)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225))
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 8)
    }
}

// MARK: - Preview

#Preview("App Icon — 180pt") {
    VStack(spacing: 24) {
        AppIconPreview(size: 180)
        HStack(spacing: 16) {
            AppIconPreview(size: 80)
            AppIconPreview(size: 60)
            AppIconPreview(size: 40)
            AppIconPreview(size: 29)
        }
    }
    .padding(32)
    .background(Color(uiColor: .systemGroupedBackground))
}
