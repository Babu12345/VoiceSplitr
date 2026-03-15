import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "camera.viewfinder",
            iconColor: .brandBlue,
            title: "Scan Any Receipt",
            description: "Take a photo of your receipt and AI will instantly extract all the items, prices, and totals."
        ),
        OnboardingPage(
            icon: "mic.fill",
            iconColor: .brandIndigo,
            title: "Voice or Manual",
            description: "Say who ordered what and AI matches items automatically — or assign items manually by tapping. Your choice."
        ),
        OnboardingPage(
            icon: "person.3.fill",
            iconColor: .brandBlueLight,
            title: "Fair Splits",
            description: "Tax and tip are split proportionally. Shared items are divided equally. Everyone pays their fair share."
        ),
        OnboardingPage(
            icon: "square.and.arrow.up",
            iconColor: .brandBlue,
            title: "Share Results",
            description: "Send the breakdown to your group via text, email, or any app. Save splits for your records."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    completeOnboarding()
                }
                .foregroundStyle(.secondary)
                .padding()
            }

            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.brandBlue : Color.gray.opacity(0.3))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, 32)

            // Action button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.brandGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            if currentPage == pages.count - 1 {
                Spacer()
                    .frame(height: 48)
            } else {
                Spacer()
                    .frame(height: 48)
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(page.iconColor)
            }

            // Title
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
