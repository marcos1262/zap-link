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
        var isClipboardImportPromptVisible: Bool = false
        var lastHandledPasteboardChangeCount: Int?
        var clipboardImportCandidate: String?

        var isOpenEnabled: Bool {
            LinkImportParser.whatsAppURL(from: phoneNumber) != nil
        }

        var shouldShowValidationError: Bool {
            !isOpenEnabled
        }
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case textFieldSubmitted
        case pasteButtonTapped
        case clipboardImportPromptTapped
        case clipboardImportPromptDismissed
        case openButtonTapped
        case scenePhaseUpdated
        case clipboardDetectionFinished(importedValue: String?, changeCount: Int)
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
                    if let importedValue = LinkImportParser.importedPhoneFieldValue(from: pasteboardString) {
                        state.phoneNumber = importedValue
                    }
                    state.lastHandledPasteboardChangeCount = pasteboard.changeCount
                }
                state.isClipboardImportPromptVisible = false
                state.clipboardImportCandidate = nil
                return .none
            case .clipboardImportPromptTapped:
                if let importedValue = state.clipboardImportCandidate {
                    state.phoneNumber = importedValue
                }
                state.isClipboardImportPromptVisible = false
                state.lastHandledPasteboardChangeCount = pasteboard.changeCount
                state.clipboardImportCandidate = nil
                return .none
            case .clipboardImportPromptDismissed:
                state.isClipboardImportPromptVisible = false
                state.lastHandledPasteboardChangeCount = pasteboard.changeCount
                state.clipboardImportCandidate = nil
                return .none
            case .openButtonTapped:
                return .run { [state] _ in
                    guard let url = LinkImportParser.whatsAppURL(from: state.phoneNumber) else { return }
                    await openURL(url)
                }
            case .scenePhaseUpdated:
                state.isPasteEnabled = pasteboard.hasString
                let changeCount = pasteboard.changeCount
                return .run { send in
                    let importedValue = await pasteboard.detectImportCandidate()
                    await send(.clipboardDetectionFinished(importedValue: importedValue, changeCount: changeCount))
                }
            case let .clipboardDetectionFinished(importedValue, changeCount):
                let currentFieldValue = LinkImportParser.importedPhoneFieldValue(from: state.phoneNumber)
                let shouldShowPrompt =
                    importedValue != nil &&
                    importedValue != currentFieldValue &&
                    state.lastHandledPasteboardChangeCount != changeCount

                state.isClipboardImportPromptVisible = shouldShowPrompt
                state.clipboardImportCandidate = shouldShowPrompt ? importedValue : nil
                return .none
            }
        }
    }
}
