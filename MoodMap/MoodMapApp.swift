import SwiftUI
import SwiftData
import UIKit

@main
struct MoodMapApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            MoodHistory.self,
            SavedPlace.self,
            PlaceReview.self,
            CheckIn.self
        ])
        container = Self.makeContainer(schema: schema)
        Self.applyGlobalNavAppearance()
    }

    static func applyGlobalNavAppearance() {
        let white  = UIColor.white
        let bg     = UIColor(red: 17/255, green: 24/255, blue: 39/255, alpha: 1)
        let accent = UIColor(red: 129/255, green: 140/255, blue: 248/255, alpha: 1)

        func makeAppearance(opaque: Bool) -> UINavigationBarAppearance {
            let a = UINavigationBarAppearance()
            if opaque { a.configureWithOpaqueBackground() }
            else      { a.configureWithTransparentBackground() }
            a.backgroundColor          = bg
            a.titleTextAttributes      = [.foregroundColor: white,
                                          .font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
            a.largeTitleTextAttributes = [.foregroundColor: white,
                                          .font: UIFont.systemFont(ofSize: 34, weight: .bold)]
            a.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: accent]
            return a
        }

        let opaque = makeAppearance(opaque: true)
        let edge   = makeAppearance(opaque: false)

        UINavigationBar.appearance().standardAppearance   = opaque
        UINavigationBar.appearance().compactAppearance    = opaque
        UINavigationBar.appearance().scrollEdgeAppearance = edge
        UINavigationBar.appearance().tintColor            = accent
        UINavigationBar.appearance().prefersLargeTitles   = true

        UITabBar.appearance().tintColor              = accent
        UITabBar.appearance().unselectedItemTintColor = UIColor(white: 1, alpha: 0.45)
    }

    static func makeContainer(schema: Schema) -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: [config]) { return c }
        deleteStoreFiles()
        if let c = try? ModelContainer(for: schema, configurations: [config]) { return c }
        let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [mem])
    }

    static func deleteStoreFiles() {
        guard let url = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        for ext in ["sqlite", "sqlite-shm", "sqlite-wal"] {
            try? FileManager.default.removeItem(at: url.appendingPathComponent("default.store.\(ext)"))
        }
        try? FileManager.default.removeItem(at: url.appendingPathComponent("default.store"))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}
