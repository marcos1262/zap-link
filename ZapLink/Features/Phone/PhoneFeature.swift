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

        var isOpenEnabled: Bool {
            PhoneFeature.whatsAppURL(from: phoneNumber) != nil
        }

        var validationMessage: String? {
            isOpenEnabled ? nil : "Enter a valid phone number"
        }
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case textFieldSubmitted
        case pasteButtonTapped
        case openButtonTapped
        case scenePhaseUpdated
    }

    private static func sanitizedDigits(from rawPhoneNumber: String) -> String {
        let digits = rawPhoneNumber.unicodeScalars.filter { scalar in
            (48...57).contains(scalar.value)
        }
        return String(String.UnicodeScalarView(digits))
    }

    private static func whatsAppURL(from rawPhoneNumber: String) -> URL? {
        let digits = Self.sanitizedDigits(from: rawPhoneNumber)
        guard !digits.isEmpty else { return nil }
        return URL(string: "https://wa.me/" + digits)
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
                    guard let url = Self.whatsAppURL(from: state.phoneNumber) else { return }
                    await openURL(url)
                }
            case .scenePhaseUpdated:
                state.isPasteEnabled = pasteboard.hasString
                return .none
            }
        }
    }
}
