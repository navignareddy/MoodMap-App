import SwiftUI
import UIKit
import SwiftData

struct ProfileView: View {
    @Query private var savedPlaces: [SavedPlace]
    @Query private var moodHistory: [MoodHistory]
    @Query private var reviews:     [PlaceReview]
    @Query private var checkIns:    [CheckIn]

    var topMood: Mood? {
        Dictionary(grouping: moodHistory, by: \.moodRaw).mapValues(\.count)
            .max(by: { $0.value < $1.value }).flatMap { Mood(rawValue: $0.key) }
    }

    var streakDays: Int {
        guard !moodHistory.isEmpty else { return 0 }
        let cal = Calendar.current
        var streak = 0; var check = cal.startOfDay(for: Date())
        let days = Set(moodHistory.map { cal.startOfDay(for: $0.date) }).sorted(by: >)
        for d in days {
            if d == check { streak += 1; check = cal.date(byAdding: .day, value: -1, to: check)! }
            else { break }
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.bg.ignoresSafeArea()
                Circle().fill(DS.accent.opacity(0.06)).frame(width: 280).blur(radius: 70).offset(x: 110, y: -130)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: topMood?.gradient ?? [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 82, height: 82)
                                    .shadow(color: (topMood?.accentColor ?? DS.accent).opacity(0.4), radius: 16)
                                Text(topMood?.emoji ?? "🗺️").font(.system(size: 40))
                            }
                            VStack(spacing: 4) {
                                Text("Explorer").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                                if let top = topMood {
                                    Text("Favourite mood: \(top.rawValue)").font(.system(size: 13, design: .rounded)).foregroundStyle(top.accentColor)
                                } else {
                                    Text("Start exploring to see your stats!").font(.system(size: 13, design: .rounded)).foregroundStyle(DS.textSecondary)
                                }
                            }
                            if streakDays > 0 {
                                HStack(spacing: 5) {
                                    Text("🔥")
                                    Text("\(streakDays)-day streak").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(DS.gold)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 5)
                                .background(DS.gold.opacity(0.1)).clipShape(Capsule())
                                .overlay(Capsule().strokeBorder(DS.gold.opacity(0.2), lineWidth: 1))
                            }
                        }
                        .padding(.top, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard2(icon: "heart.fill", color: DS.danger, value: "\(savedPlaces.count)", label: "Saved")
                            StatCard2(icon: "mappin.and.ellipse", color: DS.accentAlt, value: "\(checkIns.count)", label: "Check-Ins")
                            StatCard2(icon: "star.fill", color: DS.gold, value: "\(reviews.count)", label: "Reviews")
                            StatCard2(icon: "clock.fill", color: DS.accent, value: "\(moodHistory.count)", label: "Sessions")
                        }
                        .padding(.horizontal, 16)

                        VStack(spacing: 10) {
                            NavigationLink { MoodAnalyticsView() } label: {
                                ProfileRow(icon: "chart.bar.fill", color: DS.accent,
                                           title: "Mood Analytics", subtitle: "Charts & insights")
                            }.buttonStyle(.plain)

                            NavigationLink {
                                NavigationStack { MoodCalendarView() }
                            } label: {
                                ProfileRow(icon: "calendar", color: Color(hex: "818CF8"),
                                           title: "Mood Calendar", subtitle: "\(moodHistory.count) sessions logged")
                            }.buttonStyle(.plain)

                            NavigationLink { CheckInsHistoryView() } label: {
                                ProfileRow(icon: "mappin.and.ellipse", color: DS.accentAlt,
                                           title: "My Check-Ins", subtitle: "\(checkIns.count) total")
                            }.buttonStyle(.plain)

                            NavigationLink { MyReviewsView() } label: {
                                ProfileRow(icon: "star.bubble.fill", color: DS.gold,
                                           title: "My Reviews", subtitle: "\(reviews.count) written")
                            }.buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)

                        Button {
                            UserDefaults.standard.set(false, forKey: "isLoggedIn")
                            UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.right.square").font(.system(size: 16))
                                Text("Sign Out").font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(DS.danger)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(DS.danger.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DS.danger.opacity(0.2), lineWidth: 1))
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct StatCard2: View {
    let icon: String; let color: Color; let value: String; let label: String
    var body: some View {
        VStack(spacing: 10) {
            ZStack { Circle().fill(color.opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: icon).font(.system(size: 17)).foregroundStyle(color) }
            Text(value).font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
            Text(label).font(.system(size: 12, design: .rounded)).foregroundStyle(DS.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 18)
        .background(DS.surface).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.border, lineWidth: 1))
    }
}

struct ProfileRow: View {
    let icon: String; let color: Color; let title: String; let subtitle: String
    var body: some View {
        HStack(spacing: 13) {
            ZStack { RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(color) }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(DS.textPrimary)
                Text(subtitle).font(.system(size: 12, design: .rounded)).foregroundStyle(DS.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(DS.textMuted)
        }
        .padding(13).background(DS.surface).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DS.border, lineWidth: 1))
    }
}

struct MyReviewsView: View {
    @Query(sort: \PlaceReview.date, order: .reverse) private var reviews: [PlaceReview]
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            if reviews.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "star.slash").font(.system(size: 52)).foregroundStyle(DS.gold.opacity(0.6))
                    Text("No reviews yet").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                    Text("Visit a place and tap Review to get started.").font(.system(size: 14, design: .rounded))
                        .foregroundStyle(DS.textSecondary).multilineTextAlignment(.center).padding(.horizontal, 40)
                }
            } else {
                List {
                    ForEach(reviews) { review in
                        ReviewCard(review: review)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .listRowSeparator(.hidden)
                    }
                    .onDelete { offsets in offsets.forEach { modelContext.delete(reviews[$0]) }; try? modelContext.save() }
                }
                .listStyle(.plain).scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("My Reviews").navigationBarTitleDisplayMode(.large).toolbarColorScheme(.dark, for: .navigationBar)
        .fixNavBarAppearance()
    }
}
