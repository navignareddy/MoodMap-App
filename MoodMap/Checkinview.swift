import SwiftUI
import UIKit
import SwiftData
import MapKit

struct CheckInView: View {
    let place: Place
    let mood: Mood
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allCheckIns: [CheckIn]
    @State private var note = ""
    @State private var saved = false

    var checkInCount: Int { allCheckIns.filter { $0.placeID == place.id }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.bg.ignoresSafeArea()
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: mood.gradient,
                                                  startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 96, height: 96)
                            .shadow(color: mood.accentColor.opacity(0.4), radius: 18)
                        VStack(spacing: 3) {
                            Image(systemName: "mappin.and.ellipse").font(.system(size: 28)).foregroundStyle(.white)
                            Text("Check In").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    .padding(.top, 16)

                    VStack(spacing: 5) {
                        Text(place.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary).multilineTextAlignment(.center)
                        Text(place.category)
                            .font(.system(size: 14, design: .rounded)).foregroundStyle(mood.accentColor)
                        if checkInCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill").font(.system(size: 12)).foregroundStyle(DS.accentAlt)
                                Text("You've been here \(checkInCount) time\(checkInCount == 1 ? "" : "s")")
                                    .font(.system(size: 13, design: .rounded)).foregroundStyle(DS.accentAlt)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Add a note (optional)", systemImage: "note.text")
                            .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(DS.textSecondary)
                        ZStack(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("What are you up to here?")
                                    .font(.system(size: 14, design: .rounded)).foregroundStyle(DS.textMuted)
                                    .padding(.top, 8).padding(.leading, 4)
                            }
                            TextEditor(text: $note)
                                .font(.system(size: 14, design: .rounded)).foregroundStyle(DS.textPrimary)
                                .scrollContentBackground(.hidden).frame(height: 80).tint(DS.accent)
                        }
                    }
                    .padding(14).background(DS.surface).clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DS.border, lineWidth: 1))
                    .padding(.horizontal, 20)

                    Button {
                        let entry = CheckIn(place: place, mood: mood, note: note)
                        modelContext.insert(entry)
                        try? modelContext.save()
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { dismiss() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: saved ? "checkmark.circle.fill" : "mappin.and.ellipse")
                            Text(saved ? "Checked In!" : "Check In Now")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(LinearGradient(colors: mood.gradient, startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: mood.accentColor.opacity(0.4), radius: 10, y: 4)
                    }
                    .padding(.horizontal, 20)
                    Spacer()
                }
            }
            .navigationTitle("Check In")
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

struct CheckInsHistoryView: View {
    @Query(sort: \CheckIn.date, order: .reverse) private var checkIns: [CheckIn]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCheckIn: CheckIn?

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            if checkIns.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "mappin.slash").font(.system(size: 52)).foregroundStyle(DS.accent.opacity(0.5))
                    Text("No check-ins yet")
                        .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                    Text("Check in at places you visit to track your journey.")
                        .font(.system(size: 14, design: .rounded)).foregroundStyle(DS.textSecondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 50)
                }
            } else {
                List {
                    ForEach(checkIns) { ci in
                        Button { selectedCheckIn = ci } label: { CheckInRow(checkIn: ci) }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .listRowSeparator(.hidden)
                    }
                    .onDelete { offsets in
                        offsets.forEach { modelContext.delete(checkIns[$0]) }
                        try? modelContext.save()
                    }
                }
                .listStyle(.plain).scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Check-Ins").navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fixNavBarAppearance()
        .sheet(item: $selectedCheckIn) { ci in CheckInDetailSheet(checkIn: ci) }
    }
}

struct CheckInRow: View {
    let checkIn: CheckIn
    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: checkIn.mood.gradient,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Image(systemName: "mappin.and.ellipse").font(.system(size: 17)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(checkIn.placeName).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(DS.textPrimary).lineLimit(1)
                HStack(spacing: 5) {
                    Text(checkIn.placeCategory).font(.system(size: 12, design: .rounded)).foregroundStyle(checkIn.mood.accentColor)
                    Text("·").foregroundStyle(DS.textMuted)
                    Text(checkIn.date.relativeString).font(.system(size: 12, design: .rounded)).foregroundStyle(DS.textSecondary)
                }
                if !checkIn.note.isEmpty {
                    Text(checkIn.note).font(.system(size: 12, design: .rounded)).foregroundStyle(DS.textSecondary).lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(DS.textMuted)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(DS.surface).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DS.border, lineWidth: 1))
    }
}

struct CheckInDetailSheet: View {
    let checkIn: CheckIn
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition

    init(checkIn: CheckIn) {
        self.checkIn = checkIn
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: checkIn.latitude, longitude: checkIn.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
        )))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Map(position: $cameraPosition) {
                            Annotation(checkIn.placeName, coordinate: CLLocationCoordinate2D(
                                latitude: checkIn.latitude, longitude: checkIn.longitude)) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: checkIn.mood.gradient,
                                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "mappin.and.ellipse").font(.system(size: 16)).foregroundStyle(.white)
                                }
                            }
                        }
                        .mapStyle(.standard(elevation: .realistic)).frame(height: 200)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: checkIn.mood.gradient,
                                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 50, height: 50)
                                    Text(checkIn.mood.emoji).font(.system(size: 22))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(checkIn.placeName)
                                        .font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                                    HStack(spacing: 8) {
                                        Text(checkIn.placeCategory).font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundStyle(checkIn.mood.accentColor)
                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                            .background(checkIn.mood.accentColor.opacity(0.15)).clipShape(Capsule())
                                        Text(checkIn.mood.rawValue).font(.system(size: 12, design: .rounded)).foregroundStyle(DS.textSecondary)
                                    }
                                }
                            }

                            InfoRowSimple(icon: "clock.fill", label: "Checked In", value: checkIn.date.shortDateString, color: DS.accentAlt)

                            if !checkIn.note.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("NOTE").font(.system(size: 10, weight: .semibold, design: .rounded))
                                        .foregroundStyle(DS.textMuted).tracking(1.2)
                                    Text(checkIn.note).font(.system(size: 14, design: .rounded)).foregroundStyle(DS.textPrimary)
                                        .padding(12).background(DS.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(DS.border, lineWidth: 1))
                                }
                            }

                            Button {
                                let name = checkIn.placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                let url = URL(string: "maps://?daddr=\(checkIn.latitude),\(checkIn.longitude)&dirflg=d&q=\(name)")
                                if let url { UIApplication.shared.open(url) }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill").font(.system(size: 18))
                                    Text("Get Directions").font(.system(size: 15, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 15)
                                .background(LinearGradient(colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                                           startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Check-In")
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
