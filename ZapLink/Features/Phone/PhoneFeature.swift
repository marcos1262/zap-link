import ComposableArchitecture

import Foundation

@Reducer
struct PhoneFeature {

    @Dependency(\.pasteboard) private var pasteboard
    @Dependency(\.openURL) private var openURL

    @ObservableState
    struct State: Equatable {
        var phoneNumber: String = "+55"
        var isPasteEnabled: Bool = false
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case textFieldSubmitted
        case pasteButtonTapped
        case openButtonTapped
        case scenePhaseUpdated
    }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .textFieldSubmitted:
                return .run { send in
                    await send(.openButtonTapped)
                }
            case .pasteButtonTapped:
                if let pasteboardString = pasteboard.string {
                    state.phoneNumber = "+55" + pasteboardString
                }
                return .none
            case .openButtonTapped:
                return .run { [state] _ in
                    guard let url = URL(string: "https://wa.me/" + state.phoneNumber) else { return }
                    await openURL(url)
                }
            case .scenePhaseUpdated:
                state.isPasteEnabled = pasteboard.hasString
                return .none
            }
        }
    }
}
