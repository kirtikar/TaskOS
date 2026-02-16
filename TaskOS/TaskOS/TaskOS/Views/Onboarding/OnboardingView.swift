import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            sfSymbol: "sun.max.fill",
            symbolColor: .orange,
            title: "Your Day, Organized",
            description: "See everything due today at a glance. Start each morning with clarity and focus."
        ),
        OnboardingPage(
            sfSymbol: "tray.full.fill",
            symbolColor: .blue,
            title: "Capture Everything",
            description: "Quickly add tasks to your inbox. Organize them into projects later — or not at all."
        ),
        OnboardingPage(
            sfSymbol: "square.grid.2x2.fill",
            symbolColor: .purple,
            title: "Projects & Priorities",
            description: "Group tasks into projects. Set priorities and due dates to stay on top of what matters."
        ),
        OnboardingPage(
            sfSymbol: "bell.fill",
            symbolColor: .red,
            title: "Never Miss a Beat",
            description: "Set reminders on any task. TaskOS will notify you at just the right time."
        )
    ]

    var body: some View {
        ZStack {
            DS.Colors.groupedBG.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page carousel
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DS.Animation.standard, value: currentPage)

                // Page dots + CTA
                VStack(spacing: DS.Spacing.xl) {
                    pageDots

                    if currentPage < pages.count - 1 {
                        HStack {
                            Button("Skip") {
                                finishOnboarding()
                            }
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.secondaryLabel)

                            Spacer()

                            Button {
                                withAnimation(DS.Animation.standard) {
                                    currentPage += 1
                                }
                            } label: {
                                HStack(spacing: DS.Spacing.xs) {
                                    Text("Next")
                                        .font(DS.Typography.headline)
                                    Image(systemName: "arrow.right")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, DS.Spacing.xl)
                                .padding(.vertical, DS.Spacing.sm)
                                .background(DS.Colors.accent)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, DS.Spacing.xl)
                    } else {
                        Button {
                            finishOnboarding()
                        } label: {
                            Text("Get Started")
                                .font(DS.Typography.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DS.Spacing.md)
                                .background(DS.Colors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                        }
                        .padding(.horizontal, DS.Spacing.xl)
                    }
                }
                .padding(.bottom, DS.Spacing.xxxl)
            }
        }
    }

    private var pageDots: some View {
        HStack(spacing: DS.Spacing.xs) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? DS.Colors.accent : DS.Colors.separator)
                    .frame(width: index == currentPage ? 20 : 6, height: 6)
                    .animation(DS.Animation.quick, value: currentPage)
            }
        }
    }

    private func finishOnboarding() {
        withAnimation(DS.Animation.smooth) {
            hasSeenOnboarding = true
        }
    }
}

// MARK: - OnboardingPage Model

struct OnboardingPage {
    let sfSymbol: String
    let symbolColor: Color
    let title: String
    let description: String
}

// MARK: - OnboardingPageView

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.symbolColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(page.symbolColor.opacity(0.08))
                    .frame(width: 160, height: 160)

                Image(systemName: page.sfSymbol)
                    .font(.system(size: 52))
                    .foregroundStyle(page.symbolColor)
            }
            .scaleEffect(appeared ? 1.0 : 0.6)
            .opacity(appeared ? 1.0 : 0.0)

            // Text
            VStack(spacing: DS.Spacing.sm) {
                Text(page.title)
                    .font(DS.Typography.largeTitle)
                    .foregroundStyle(DS.Colors.label)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1.0 : 0.0)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(DS.Animation.bouncy.delay(0.1)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

#Preview {
    OnboardingView()
        .environment(ThemeManager.shared)
}
