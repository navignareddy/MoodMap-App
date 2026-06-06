import SwiftUI
import UIKit

struct RootView: View {
    @AppStorage("isLoggedIn")        private var isLoggedIn       = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if !isLoggedIn {
            AuthView()
        } else if !hasSeenOnboarding {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    @State private var locationService = LocationService()
    @State private var selectedTab     = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(locationService: locationService)
                .tabItem { Label("Discover", systemImage: "sparkles") }
                .tag(0)

            SavedPlacesView()
                .tabItem { Label("Saved", systemImage: "heart.fill") }
                .tag(1)

            MoodHistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(2)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(3)
        }
        .tint(Color(hex: "7C3AED"))
        .fixNavBarAppearance()
        .onAppear { locationService.requestLocation() }
    }
}
