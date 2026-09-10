import SwiftUI

@main
struct ByeJetLagApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                HomeView()
                    .environmentObject(appState)
            } else {
                OnboardingView()
                    .environmentObject(appState)
            }
        }
    }
}
