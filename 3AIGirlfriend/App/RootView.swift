import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                ChatView()
            } else {
                OnboardingView()
            }
        }
        .fullScreenCover(isPresented: $appState.showPaywall) {
            PaywallView()
                .environmentObject(appState)
                .environmentObject(appState.store)
        }
        .sheet(item: $appState.showFeatureSheet) { kind in
            FeaturePaywallSheet(kind: kind)
                .environmentObject(appState)
        }
    }
}

struct ContentView: View {
    @StateObject private var store: StoreManager
    @StateObject private var appState: AppState

    init() {
        let store = StoreManager()
        _store = StateObject(wrappedValue: store)
        _appState = StateObject(wrappedValue: AppState(store: store))
    }

    var body: some View {
        RootView()
            .environmentObject(appState)
            .environmentObject(store)
            .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
