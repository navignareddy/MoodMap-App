import SwiftUI
import SwiftData

struct MoodAnalyticsView: View {
    @Query(sort: \MoodHistory.date, order: .reverse) private var history: [MoodHistory]
    @State private var period: Period = .week

    enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }

    private let cal = Calendar.current

    var filtered: [MoodHistory] {
        let now = Date()
        switch period {
        case .week:
            return history.filter { $0.date >= cal.date(byAdding: .day, value: -7, to: now)! }
        case .month:
            return history.filter { $0.date >= cal.date(byAdding: .month, value: -1, to: now)! }
        case .all:
            return history
        }
    }

    var moodCounts: [(mood: Mood, count: Int)] {
        Dictionary(grouping: filtered, by: \.moodRaw)
            .compactMap { k, v in Mood(rawValue: k).map { ($0, v.count) } }
            .sorted { $0.count > $1.count }
    }

    var weeklyData: [(label: String, moods: [MoodHistory])] {
        (0..<7).reversed().map { offset -> (String, [MoodHistory]) in
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            let fmt = DateFormatter()
            fmt.dateFormat = offset == 0 ? "'Today'" : "EEE"
            return (fmt.string(from: date), history.filter { cal.isDate($0.date, inSameDayAs: date) })
        }
    }

    var topMood: Mood? { moodCounts.first?.mood }
    var maxCount: Int  { moodCounts.map(\.count).max() ?? 1 }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            if history.isEmpty {
                AnalyticsEmptyView()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        Picker("Period", selection: $period) {
                            ForEach(Period.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 18)
                        .padding(.top, 14)

                        if let top = topMood {
                            TopMoodCard(mood: top, totalSessions: filtered.count)
                        }

                        WeeklyChartCard(weeklyData: weeklyData)

                        if !moodCounts.isEmpty {
                            BreakdownCard(moodCounts: moodCounts, maxCount: maxCount)
                        }

                        Spacer(minLength: 30)
                    }
                }
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fixNavBarAppearance()
    }
}

private struct AnalyticsEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 52))
                .foregroundStyle(DS.accent.opacity(0.5))
            Text("No data yet")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(DS.textPrimary)
            Text("Explore moods to start seeing your analytics.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(DS.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
        }
    }
}

private struct TopMoodCard: View {
    let mood: Mood
    let totalSessions: Int

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: mood.gradient,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                    .shadow(color: mood.accentColor.opacity(0.35), radius: 12)
                Text(mood.emoji).font(.system(size: 26))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("TOP MOOD")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(DS.textMuted).tracking(1.2)
                Text(mood.rawValue)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.textPrimary)
                Text(mood.description)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(DS.textSecondary)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("\(totalSessions)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.textPrimary)
                Text("sessions")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(DS.textMuted)
            }
        }
        .padding(16)
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.border, lineWidth: 1))
        .padding(.horizontal, 16)
    }
}

private struct WeeklyChartCard: View {
    let weeklyData: [(label: String, moods: [MoodHistory])]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("7-DAY MOOD CHART")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(DS.textMuted).tracking(1.2)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weeklyData, id: \.label) { day in
                    DayBarColumn(day: day)
                }
            }
        }
        .padding(16)
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.border, lineWidth: 1))
        .padding(.horizontal, 16)
    }
}

private struct DayBarColumn: View {
    let day: (label: String, moods: [MoodHistory])

    var body: some View {
        VStack(spacing: 6) {
            if day.moods.isEmpty {
                RoundedRectangle(cornerRadius: 6)
                    .fill(DS.surface2)
                    .frame(height: 60)
            } else {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: day.moods[0].mood.gradient,
                            startPoint: .top, endPoint: .bottom))
                        .frame(height: CGFloat(min(day.moods.count * 30 + 30, 120)))
                    if day.moods.count > 1 {
                        Text("+\(day.moods.count - 1)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.bottom, 4)
                    }
                }
            }
            Text(day.label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(DS.textMuted).lineLimit(1)
            if let first = day.moods.first {
                Text(first.mood.emoji).font(.system(size: 12))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct BreakdownCard: View {
    let moodCounts: [(mood: Mood, count: Int)]
    let maxCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("MOOD BREAKDOWN")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(DS.textMuted).tracking(1.2)

            ForEach(moodCounts, id: \.mood) { item in
                BreakdownRow(item: item, maxCount: maxCount)
            }
        }
        .padding(16)
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.border, lineWidth: 1))
        .padding(.horizontal, 16)
    }
}

private struct BreakdownRow: View {
    let item: (mood: Mood, count: Int)
    let maxCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(item.mood.emoji)
                .font(.system(size: 18)).frame(width: 28)
            Text(item.mood.rawValue)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(DS.textPrimary)
                .frame(width: 90, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(DS.surface2)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: item.mood.gradient,
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * (Double(item.count) / Double(maxCount))))
                }
            }
            .frame(height: 10)
            Text("\(item.count)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(DS.textSecondary)
                .frame(width: 24, alignment: .trailing)
        }
    }
}
