import ComposableArchitecture
import SwiftUI

@main
struct ZapLinkApp: App {

    private let store: StoreOf<PhoneFeature>

    init() {
        self.store = Store(initialState: PhoneFeature.State()) {
            PhoneFeature()
        }

        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor(named: "AccentColor")!
        ]
    }

    var body: some Scene {
        WindowGroup {
            PhoneView(store: store)
        }
    }
}
