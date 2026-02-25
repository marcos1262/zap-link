import ComposableArchitecture
import SwiftUI

@main
struct ZapLinkApp: App {

    private let store: StoreOf<PhoneFeature>

    init() {
        self.store = Store(initialState: PhoneFeature.State()) {
            PhoneFeature()
        }

        let accentColor = UIColor(named: "AccentColor") ?? .systemGreen
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: accentColor
        ]
    }

    var body: some Scene {
        WindowGroup {
            PhoneView(store: store)
        }
    }
}
