import SwiftUI
import UIKit
import SwiftData

struct MoodHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodHistory.date, order: .reverse) private var moodHistory: [MoodHistory]
    @State private var showClearAlert = false
    @State private var selectedEntry: MoodHistory?

    var body: some View {
        NavigationStack {
            ZStack {
                DS.bg.ignoresSafeArea()
                if moodHistory.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.xmark").font(.system(size: 52))
                            .foregroundStyle(DS.accent.opacity(0.6))
                        Text("No mood history yet")
                            .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                        Text("Start exploring moods and your sessions will appear here.")
                            .font(.system(size: 14, design: .rounded)).foregroundStyle(DS.textSecondary)
                            .multilineTextAlignment(.center).padding(.horizontal, 50)
                    }
                } else {
                    List {
                        ForEach(moodHistory) { entry in
                            Button { selectedEntry = entry } label: {
                                MoodHistoryRow(entry: entry)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            for idx in offsets { modelContext.delete(moodHistory[idx]) }
                            try? modelContext.save()
                        }
                    }
                    .listStyle(.plain).scrollContentBackground(.hidden)
                    .animation(.default, value: moodHistory.count)
                }
            }
            .navigationTitle("Mood History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if !moodHistory.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All") { showClearAlert = true }
                            .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(DS.danger)
                    }
                }
            }
            .alert("Clear All History?", isPresented: $showClearAlert) {
                Button("Clear All", role: .destructive) {
                    moodHistory.forEach { modelContext.delete($0) }
                    try? modelContext.save()
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This will permanently remove all mood history.") }
            .sheet(item: $selectedEntry) { entry in
                MoodSessionDetailSheet(entry: entry)
            }
        }
    }
}

struct MoodHistoryRow: View {
    let entry: MoodHistory
    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: entry.mood.gradient,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Text(entry.mood.emoji).font(.system(size: 21))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.mood.rawValue)
                    .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                HStack(spacing: 6) {
                    Label("\(entry.placeCount) places", systemImage: "mappin.and.ellipse")
                        .font(.system(size: 12, design: .rounded)).foregroundStyle(entry.mood.accentColor)
                    Text("·").foregroundStyle(DS.textMuted)
                    Text(entry.city).font(.system(size: 12, design: .rounded)).foregroundStyle(DS.textSecondary).lineLimit(1)
                }
                Text(entry.date.shortDateString).font(.system(size: 11, design: .rounded)).foregroundStyle(DS.textMuted)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(DS.textMuted)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(DS.surface).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DS.border, lineWidth: 1))
    }
}

struct MoodSessionDetailSheet: View {
    let entry: MoodHistory
    @Environment(\.dismiss) private var dismiss
    @Query private var allHistory: [MoodHistory]

    var sameMoodSessions: [MoodHistory] {
        allHistory.filter { $0.moodRaw == entry.moodRaw && $0.id != entry.id }
            .sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: entry.mood.gradient,
                                                      startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 88, height: 88)
                                .shadow(color: entry.mood.accentColor.opacity(0.4), radius: 16)
                            Text(entry.mood.emoji).font(.system(size: 42))
                        }
                        .padding(.top, 10)

                        VStack(spacing: 6) {
                            Text(entry.mood.rawValue)
                                .font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                            Text(entry.date.shortDateString)
                                .font(.system(size: 14, design: .rounded)).foregroundStyle(DS.textSecondary)
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatPillSmall(icon: "mappin.and.ellipse", value: "\(entry.placeCount)", label: "Places Found", color: entry.mood.accentColor)
                            StatPillSmall(icon: "location.fill", value: entry.city, label: "Location", color: DS.accent)
                        }
                        .padding(.horizontal, 20)

                        if !sameMoodSessions.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("OTHER \(entry.mood.rawValue.uppercased()) SESSIONS")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(DS.textMuted).tracking(1.2).padding(.horizontal, 20)

                                ForEach(sameMoodSessions) { s in
                                    HStack(spacing: 12) {
                                        Text(s.mood.emoji).font(.system(size: 18))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(s.city).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(DS.textPrimary)
                                            Text(s.date.shortDateString).font(.system(size: 11, design: .rounded)).foregroundStyle(DS.textMuted)
                                        }
                                        Spacer()
                                        Text("\(s.placeCount) places").font(.system(size: 12, design: .rounded)).foregroundStyle(DS.textSecondary)
                                    }
                                    .padding(.horizontal, 14).padding(.vertical, 10)
                                    .background(DS.surface).clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(DS.border, lineWidth: 1))
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationTitle(entry.mood.rawValue + " Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(DS.accent)
                }
            }
        }
    }
}

struct StatPillSmall: View {
    let icon: String; let value: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
            Text(value).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary).lineLimit(1)
            Text(label).font(.system(size: 11, design: .rounded)).foregroundStyle(DS.textMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(DS.surface).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DS.border, lineWidth: 1))
    }
}
