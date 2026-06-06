import SwiftUI

struct AppDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0

    struct DemoStep {
        let icon:        String
        let title:       String
        let description: String
        let tip:         String
        let color:       Color
    }

    let steps: [DemoStep] = [
        DemoStep(icon: "hand.tap.fill",
                 title: "Pick your mood",
                 description: "On the home screen you will see 6 mood cards — Relaxed, Social, Adventurous, Focused, Creative, and Mindful. Simply tap the one that matches how you feel right now.",
                 tip: "No typing or searching needed — just tap.",
                 color: Color(hex: "6366F1")),

        DemoStep(icon: "mappin.and.ellipse",
                 title: "Get nearby places",
                 description: "MoodMap instantly finds real places near your location on OpenStreetMap that match your mood, ranked from closest to furthest with distance shown.",
                 tip: "Results use your live GPS location automatically.",
                 color: Color(hex: "059669")),

        DemoStep(icon: "map.fill",
                 title: "Explore on the map",
                 description: "Tap the map icon at the top right of the results screen to see all recommended spots as coloured pins on a full-screen map. Tap a pin for a quick preview.",
                 tip: "Pinch to zoom and pan to explore the area.",
                 color: Color(hex: "0D9488")),

        DemoStep(icon: "heart.fill",
                 title: "Save your favourites",
                 description: "On the place detail screen, tap the heart button to save any place. Your saved places appear in the Saved tab and stay there even after closing the app.",
                 tip: "Tap the directions button to open Apple Maps.",
                 color: Color(hex: "F43F5E")),

        DemoStep(icon: "calendar",
                 title: "Track your moods",
                 description: "Every search is automatically logged in Mood History. Open the calendar from the home screen to see a colour-coded monthly view of your mood patterns.",
                 tip: "Tap any past day to add a mood or see the timeline.",
                 color: Color(hex: "9333EA")),

        DemoStep(icon: "chart.bar.fill",
                 title: "View your analytics",
                 description: "Go to Profile, then Mood Analytics to see a 7-day activity chart, your top mood, and a full breakdown across all moods you have explored.",
                 tip: "Switch between Week, Month, and All Time views.",
                 color: Color(hex: "EA580C")),
    ]

    var current: DemoStep { steps[step] }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0F0C29"), Color(hex: "1a1040")],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            Circle().fill(current.color.opacity(0.1))
                .frame(width: 300).blur(radius: 70).offset(y: -140)
                .animation(.easeInOut(duration: 0.5), value: step)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 24).padding(.top, 20)
                }

                Spacer()

                VStack(spacing: 30) {
                    ZStack {
                        Circle().fill(current.color.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Circle().strokeBorder(current.color.opacity(0.35), lineWidth: 1.5)
                            .frame(width: 100, height: 100)
                        Image(systemName: current.icon)
                            .font(.system(size: 38, weight: .medium))
                            .foregroundStyle(current.color)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: step)

                    VStack(spacing: 12) {
                        Text(current.title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text(current.description)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 30)
                    }
                    .id(step)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    .animation(.easeInOut(duration: 0.3), value: step)

                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(current.color)
                        Text(current.tip)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(current.color)
                    }
                    .padding(.horizontal, 18).padding(.vertical, 11)
                    .background(current.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(current.color.opacity(0.22), lineWidth: 1))
                    .padding(.horizontal, 28)
                    .animation(.easeInOut(duration: 0.3), value: step)
                }

                Spacer()

                VStack(spacing: 18) {
                    HStack(spacing: 7) {
                        ForEach(0..<steps.count, id: \.self) { i in
                            Capsule()
                                .fill(i == step ? current.color : Color.white.opacity(0.2))
                                .frame(width: i == step ? 22 : 7, height: 7)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: step)
                        }
                    }

                    HStack(spacing: 12) {
                        if step > 0 {
                            Button { withAnimation { step -= 1 } } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .frame(width: 46, height: 46)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                                    .overlay(Circle().strokeBorder(.white.opacity(0.1), lineWidth: 1))
                            }
                        }

                        Button {
                            if step < steps.count - 1 {
                                withAnimation { step += 1 }
                            } else {
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(step < steps.count - 1 ? "Next" : "Got it, let's go!")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                Image(systemName: step < steps.count - 1 ? "arrow.right" : "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(LinearGradient(
                                colors: [current.color, current.color.opacity(0.8)],
                                startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 26)
                }
                .padding(.bottom, 46)
            }
        }
    }
}
