import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    @State private var animateIn   = false

    struct OnboardingPage {
        let emoji: String
        let title: String
        let subtitle: String
        let colors: [Color]
        let accent: Color
    }

    let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "🗺️",
            title: "Welcome to MoodMap",
            subtitle: "Discover places around you that match exactly how you feel right now.",
            colors: [Color(hex: "1a1040"), Color(hex: "302B63")],
            accent: Color(hex: "A78BFA")
        ),
        OnboardingPage(
            emoji: "✨",
            title: "Pick Your Mood",
            subtitle: "Choose from 6 moods — Relaxed, Social, Adventurous, Focused, Creative or Mindful — and get instant nearby recommendations.",
            colors: [Color(hex: "0f2027"), Color(hex: "203a43")],
            accent: Color(hex: "34D399")
        ),
        OnboardingPage(
            emoji: "📍",
            title: "Check In & Review",
            subtitle: "Mark your visits, rate places, upload photos and track your mood journey over time.",
            colors: [Color(hex: "1a0533"), Color(hex: "3b1060")],
            accent: Color(hex: "F472B6")
        ),
        OnboardingPage(
            emoji: "📊",
            title: "Track Your Journey",
            subtitle: "See your mood patterns, favourite spots and exploration history all in one beautiful profile.",
            colors: [Color(hex: "0c1445"), Color(hex: "1a2980")],
            accent: Color(hex: "FBBF24")
        )
    ]

    var body: some View {
        ZStack {

            LinearGradient(
                colors: pages[currentPage].colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.7), value: currentPage)

            Circle()
                .fill(pages[currentPage].accent.opacity(0.15))
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(x: 100, y: -200)
                .animation(.easeInOut(duration: 0.7), value: currentPage)

            Circle()
                .fill(pages[currentPage].accent.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: -120, y: 250)
                .animation(.easeInOut(duration: 0.7), value: currentPage)

            VStack(spacing: 0) {

                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                hasSeenOnboarding = true
                            }
                        }
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(pages[currentPage].accent.opacity(0.3), lineWidth: 2)
                        .frame(width: 130, height: 130)

                    Circle()
                        .fill(pages[currentPage].accent.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Text(pages[currentPage].emoji)
                        .font(.system(size: 62))
                }
                .scaleEffect(animateIn ? 1.0 : 0.6)
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateIn)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: currentPage)

                Spacer().frame(height: 40)

                VStack(spacing: 14) {
                    Text(pages[currentPage].title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .id("title-\(currentPage)")
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal:   .move(edge: .leading).combined(with: .opacity)
                        ))

                    Text(pages[currentPage].subtitle)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .id("sub-\(currentPage)")
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal:   .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                .animation(.easeInOut(duration: 0.35), value: currentPage)

                Spacer()

                VStack(spacing: 36) {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage
                                      ? pages[currentPage].accent
                                      : Color.white.opacity(0.25))
                                .frame(width: i == currentPage ? 28 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(.easeInOut(duration: 0.35)) { currentPage += 1 }
                            animateIn = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation { animateIn = true }
                            }
                        } else {
                            withAnimation { hasSeenOnboarding = true }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text(currentPage < pages.count - 1 ? "Next" : "Let's Explore!")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "sparkles")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(pages[currentPage].colors[0])
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(pages[currentPage].accent)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: pages[currentPage].accent.opacity(0.4), radius: 14, y: 6)
                    }
                    .padding(.horizontal, 28)
                }
                .padding(.bottom, 52)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation { animateIn = true }
            }
        }
    }
}
