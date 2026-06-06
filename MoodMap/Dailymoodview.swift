import SwiftUI
import SwiftData

struct MoodCalendarView: View {
    @Query(sort: \MoodHistory.date, order: .reverse) private var history: [MoodHistory]

    private let cal = Calendar.current
    @State private var displayedMonth = Date()
    @State private var selectedDay:    Date?   = nil
    @State private var showLogMood     = false
    @State private var showDayDetail   = false

    private var monthStart: Date {
        cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))!
    }
    private var daysInMonth: Int {
        cal.range(of: .day, in: .month, for: displayedMonth)!.count
    }
    private var firstWeekday: Int {
        (cal.component(.weekday, from: monthStart) + 6) % 7
    }
    private func date(for day: Int) -> Date? {
        cal.date(from: DateComponents(
            year:  cal.component(.year,  from: displayedMonth),
            month: cal.component(.month, from: displayedMonth),
            day:   day))
    }
    private func isFuture(_ day: Int) -> Bool {
        guard let d = date(for: day) else { return false }
        return cal.startOfDay(for: d) > cal.startOfDay(for: Date())
    }
    private var moodsByDay: [String: [MoodHistory]] {
        var dict: [String: [MoodHistory]] = [:]
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        for e in history { dict[fmt.string(from: e.date), default: []].append(e) }
        return dict
    }
    private func moodsOnDay(_ day: Int) -> [MoodHistory] {
        guard let d = date(for: day) else { return [] }
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        return (moodsByDay[fmt.string(from: d)] ?? []).sorted { $0.date < $1.date }
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth)! } label: {
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DS.accent).frame(width: 40, height: 40)
                            .background(DS.surface).clipShape(Circle())
                            .overlay(Circle().strokeBorder(DS.border, lineWidth: 1))
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(displayedMonth, format: .dateTime.month(.wide))
                            .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                        Text(displayedMonth, format: .dateTime.year())
                            .font(.system(size: 13, design: .rounded)).foregroundStyle(DS.textSecondary)
                    }
                    Spacer()
                    Button { displayedMonth = cal.date(byAdding: .month, value: 1, to: displayedMonth)! } label: {
                        Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DS.accent).frame(width: 40, height: 40)
                            .background(DS.surface).clipShape(Circle())
                            .overlay(Circle().strokeBorder(DS.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 14)

                HStack(spacing: 0) {
                    ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                        Text(d).font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(DS.textMuted).frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 10).padding(.bottom, 8)

                let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
                LazyVGrid(columns: cols, spacing: 6) {
                    ForEach(0..<firstWeekday, id: \.self) { _ in Color.clear.frame(height: 58) }
                    ForEach(1...daysInMonth, id: \.self) { day in
                        let dayMoods = moodsOnDay(day)
                        let isToday  = cal.isDateInToday(date(for: day) ?? .distantPast)
                        let future   = isFuture(day)
                        Button {
                            guard !future else { return }
                            selectedDay = date(for: day)
                            if dayMoods.isEmpty { showLogMood = true }
                            else { showDayDetail = true }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 11)
                                    .fill(dayMoods.isEmpty
                                        ? AnyShapeStyle(DS.surface)
                                        : AnyShapeStyle(LinearGradient(
                                            colors: dayMoods[0].mood.gradient,
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                          ).opacity(0.8)))
                                if isToday {
                                    RoundedRectangle(cornerRadius: 11).strokeBorder(DS.accent, lineWidth: 2)
                                }
                                VStack(spacing: 2) {
                                    Text("\(day)")
                                        .font(.system(size: 13, weight: isToday ? .bold : .medium, design: .rounded))
                                        .foregroundStyle(future ? DS.textMuted.opacity(0.4) : dayMoods.isEmpty ? DS.textSecondary : .white)
                                    if let mood = dayMoods.first {
                                        Text(mood.mood.emoji).font(.system(size: 13))
                                    } else if !future {
                                        Image(systemName: "plus").font(.system(size: 8, weight: .medium))
                                            .foregroundStyle(DS.textMuted.opacity(0.35))
                                    }
                                }
                            }
                            .frame(height: 58)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)

                Spacer(minLength: 14)

                VStack(alignment: .leading, spacing: 10) {
                    Text("LEGEND").font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(DS.textMuted).tracking(1.5)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Mood.allCases, id: \.self) { mood in
                            HStack(spacing: 5) {
                                Circle().fill(LinearGradient(colors: mood.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 12, height: 12)
                                Text(mood.rawValue).font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(DS.textSecondary).lineLimit(1)
                            }
                        }
                    }
                }
                .padding(14).background(DS.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DS.border, lineWidth: 1))
                .padding(.horizontal, 14).padding(.bottom, 16)
            }
        }
        .navigationTitle("Mood Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showLogMood) {
            if let day = selectedDay {
                LogMoodForDayView(date: day)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showDayDetail) {
            if let day = selectedDay {
                DayDetailSheet(date: day)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(DS.bg)
            }
        }
    }
}

struct DayDetailSheet: View {
    let date: Date
    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodHistory.date, order: .forward) private var allHistory: [MoodHistory]
    @State private var showLogMore = false
    private let cal = Calendar.current

    var dayMoods: [MoodHistory] {
        let start = cal.startOfDay(for: date)
        let end   = cal.date(byAdding: .day, value: 1, to: start)!
        return allHistory.filter { $0.date >= start && $0.date < end }
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("Day Overview")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(DS.textPrimary)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(DS.accent)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider().background(DS.border)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Text(date, format: .dateTime.weekday(.wide).day().month(.wide).year())
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(DS.textPrimary)
                            .padding(.top, 16)

                        if dayMoods.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "moon.zzz").font(.system(size: 40))
                                    .foregroundStyle(DS.textMuted)
                                Text("No moods logged for this day.")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(DS.textSecondary)
                            }
                            .padding(.top, 30)
                        } else {
                            HStack(spacing: 10) {
                                ForEach(dayMoods) { entry in
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(colors: entry.mood.gradient,
                                                startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 52, height: 52)
                                            .shadow(color: entry.mood.accentColor.opacity(0.3), radius: 8)
                                        Text(entry.mood.emoji).font(.system(size: 24))
                                    }
                                }
                            }

                            VStack(spacing: 10) {
                                Text("TIMELINE")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(DS.textMuted).tracking(1.5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)

                                ForEach(dayMoods) { entry in
                                    HStack(spacing: 14) {
                                        VStack(spacing: 0) {
                                            Circle().fill(entry.mood.accentColor).frame(width: 10, height: 10)
                                            if entry.id != dayMoods.last?.id {
                                                Rectangle().fill(DS.border).frame(width: 2).frame(maxHeight: .infinity)
                                            }
                                        }
                                        .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                Text(entry.mood.emoji).font(.system(size: 20))
                                                Text(entry.mood.rawValue)
                                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                                    .foregroundStyle(DS.textPrimary)
                                                Spacer()
                                                Text(entry.date.timeString)
                                                    .font(.system(size: 12, design: .rounded))
                                                    .foregroundStyle(DS.textMuted)
                                            }
                                            Label(
                                                entry.placeCount > 0 ? "\(entry.placeCount) places" : "Manual entry",
                                                systemImage: entry.placeCount > 0 ? "mappin.and.ellipse" : "pencil"
                                            )
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(entry.placeCount > 0 ? entry.mood.accentColor : DS.textMuted)
                                        }
                                        .padding(12).background(DS.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(DS.border, lineWidth: 1))
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        Button { showLogMore = true } label: {
                            Label("Log Another Mood for This Day", systemImage: "plus.circle.fill")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(DS.accent).frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(DS.accent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(DS.accent.opacity(0.25), lineWidth: 1))
                        }
                        .padding(.horizontal, 20)
                        Spacer(minLength: 30)
                    }
                }
            }
        }
        .sheet(isPresented: $showLogMore) {
            LogMoodForDayView(date: date)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct LogMoodForDayView: View {
    let date: Date
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @State private var selectedMood: Mood? = nil
    @State private var saved = false

    var body: some View {
        NavigationStack {
            ZStack {
                DS.bg.ignoresSafeArea()
                VStack(spacing: 22) {
                    VStack(spacing: 5) {
                        Text(date, format: .dateTime.weekday(.wide).month(.wide).day())
                            .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                        Text("How were you feeling?")
                            .font(.system(size: 14, design: .rounded)).foregroundStyle(DS.textSecondary)
                    }
                    .padding(.top, 10)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Mood.allCases, id: \.self) { mood in
                            Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { selectedMood = mood } } label: {
                                VStack(spacing: 7) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(colors: mood.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 56, height: 56)
                                            .shadow(color: mood.accentColor.opacity(selectedMood == mood ? 0.5 : 0.12),
                                                    radius: selectedMood == mood ? 10 : 3)
                                        Text(mood.emoji).font(.system(size: 26))
                                    }
                                    .scaleEffect(selectedMood == mood ? 1.1 : 1.0)
                                    Text(mood.rawValue)
                                        .font(.system(size: 11, weight: selectedMood == mood ? .bold : .regular, design: .rounded))
                                        .foregroundStyle(selectedMood == mood ? mood.accentColor : DS.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)

                    Button {
                        guard let mood = selectedMood else { return }
                        let entry = MoodHistory(mood: mood, placeCount: 0, city: "Manual entry", date: date)
                        modelContext.insert(entry)
                        try? modelContext.save()
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { dismiss() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: saved ? "checkmark.circle.fill" : "calendar.badge.plus")
                            Text(saved ? "Logged!" : "Log This Mood")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(selectedMood != nil
                            ? LinearGradient(colors: selectedMood!.gradient, startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [DS.surface2, DS.surface2], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(selectedMood == nil)
                    .padding(.horizontal, 20)
                    Spacer()
                }
            }
            .navigationTitle("Log Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(DS.textSecondary)
                }
            }
        }
    }
}
