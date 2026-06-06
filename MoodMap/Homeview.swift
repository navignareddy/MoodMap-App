import SwiftUI
import SwiftData

struct HomeView: View {
    var locationService: LocationService
    @State private var animateCards = false
    @State private var navigationPath = NavigationPath()
    @State private var showCalendar = false
    @Query(sort: \MoodHistory.date, order: .reverse) private var history: [MoodHistory]
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        return "Good evening"
    }

    var streakDays: Int {
        guard !history.isEmpty else { return 0 }
        let cal = Calendar.current; var streak = 0; var check = cal.startOfDay(for: Date())
        let days = Array(Set(history.map { cal.startOfDay(for: $0.date) })).sorted(by: >)
        for d in days { if d == check { streak += 1; check = cal.date(byAdding: .day, value: -1, to: check)! } else { break } }
        return streak
    }

    var todayMoods: [MoodHistory] { history.filter { Calendar.current.isDateInToday($0.date) } }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                DS.bg.ignoresSafeArea()
                Circle().fill(Color(hex: "6366F1").opacity(0.12)).frame(width: 320).blur(radius: 90).offset(x: -80, y: -180)
                Circle().fill(Color(hex: "0D9488").opacity(0.08)).frame(width: 260).blur(radius: 70).offset(x: 130, y: 180)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        VStack(spacing: 14) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("MOODMAP").font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundStyle(DS.accent).tracking(2.5)
                                    Text(greeting + "!").font(.system(size: 13, design: .rounded)).foregroundStyle(DS.textSecondary)
                                    Text("How are you\nfeeling today?")
                                        .font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                                }
                                Spacer()
                                VStack(spacing: 8) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "location.fill").font(.system(size: 10))
                                        Text(locationService.cityName).font(.system(size: 11, weight: .medium, design: .rounded)).lineLimit(1)
                                    }
                                    .foregroundStyle(DS.accent)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(DS.accent.opacity(0.12)).clipShape(Capsule())
                                    .overlay(Capsule().strokeBorder(DS.accent.opacity(0.3), lineWidth: 1))

                                    Button { showCalendar = true } label: {
                                        Image(systemName: "calendar").font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(DS.accent).frame(width: 32, height: 32)
                                            .background(DS.accent.opacity(0.1)).clipShape(Circle())
                                            .overlay(Circle().strokeBorder(DS.accent.opacity(0.25), lineWidth: 1))
                                    }
                                }
                            }

                            HStack(spacing: 13) {
                                VStack(spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text("🔥").font(.system(size: 15))
                                        Text("\(streakDays)").font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                                    }
                                    Text("streak").font(.system(size: 9, design: .rounded)).foregroundStyle(DS.textMuted)
                                }.frame(minWidth: 50)

                                Divider().background(DS.border).frame(height: 28)

                                VStack(alignment: .leading, spacing: 3) {
                                    if todayMoods.isEmpty {
                                        Text("No mood logged today").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(DS.textPrimary)
                                        Text("Tap a mood to get started!").font(.system(size: 11, design: .rounded)).foregroundStyle(DS.textSecondary)
                                    } else {
                                        Text("Today's moods").font(.system(size: 11, design: .rounded)).foregroundStyle(DS.textSecondary)
                                        HStack(spacing: 4) {
                                            ForEach(todayMoods.prefix(4)) { entry in Text(entry.mood.emoji).font(.system(size: 17)) }
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14).padding(.vertical, 11)
                            .background(DS.surface).clipShape(RoundedRectangle(cornerRadius: 13))
                            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(DS.border, lineWidth: 1))
                        }
                        .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 18)

                        HStack {
                            Text("SELECT YOUR MOOD").font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(DS.textMuted).tracking(2)
                            Spacer()
                        }.padding(.horizontal, 18).padding(.bottom, 10)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(Mood.allCases.enumerated()), id: \.element) { idx, mood in
                                Button { navigationPath.append(mood) } label: { MoodCard(mood: mood) }
                                    .buttonStyle(MoodButtonStyle())
                                    .scaleEffect(animateCards ? 1 : 0.84).opacity(animateCards ? 1 : 0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(idx) * 0.06), value: animateCards)
                            }
                        }
                        .padding(.horizontal, 16).padding(.bottom, 28)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Mood.self) { mood in
                RecommendationsView(mood: mood, locationService: locationService)
            }
            .sheet(isPresented: $showCalendar) {
                NavigationStack { MoodCalendarView() }
            }
            .onAppear { withAnimation { animateCards = true } }
        }
    }
}

struct MoodButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct MoodCard: View {
    let mood: Mood
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: mood.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.05))
            RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.14), lineWidth: 1)
            VStack(spacing: 9) {
                Text(mood.emoji).font(.system(size: 42))
                Text(mood.rawValue).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text(mood.description).font(.system(size: 11, design: .rounded)).foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center).lineLimit(2).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 10).padding(.vertical, 18)
        }
        .shadow(color: mood.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}
