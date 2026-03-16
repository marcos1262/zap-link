import ComposableArchitecture
import XCTest

@testable import ZapLink

@MainActor
final class PhoneFeatureTests: XCTestCase {

    var urlParameters: [URL]!
    var openURLMock: OpenURLEffect!
    var pasteboardMock: PasteboardMock!

    var store: TestStoreOf<PhoneFeature>!

    override func setUp() async throws {
        urlParameters = []
        openURLMock = OpenURLEffect { url in
            await MainActor.run { [weak self] in
                self?.urlParameters.append(url)
            }
            return false
        }
        pasteboardMock = PasteboardMock()

        store = TestStore(initialState: PhoneFeature.State(), reducer: {
            PhoneFeature()
        }) {
            $0.openURL = openURLMock
            $0.pasteboard = pasteboardMock
        }
    }

    func test_livePasteboardDependency_usesGeneralPasteboard() {
        let livePasteboard = PasteboardKey.liveValue as? UIPasteboard

        XCTAssertTrue(livePasteboard === UIPasteboard.general)
    }

    func test_initialState() {
        XCTAssertEqual(store.state, PhoneFeature.State(phoneNumber: "+55",
                                                       isPasteEnabled: false,
                                                       isClipboardImportPromptVisible: false,
                                                       lastHandledPasteboardChangeCount: nil,
                                                       clipboardImportCandidate: nil))
        XCTAssertTrue(store.state.isOpenEnabled)
        XCTAssertFalse(store.state.shouldShowValidationError)
    }

    func test_setBinding() async {
        await store.send(.set(\.phoneNumber, "123")) {
            $0.phoneNumber = "123"
        }
    }

    func test_textFieldSubmitted() async {
        await store.send(.textFieldSubmitted)

        await store.receive(.openButtonTapped)

        XCTAssertEqual(urlParameters, [URL(string: "https://wa.me/55")!])
    }

    func test_pasteButtonTapped_when_stringIsNil() async {
        pasteboardMock.string = nil

        await store.send(.pasteButtonTapped)
    }

    func test_pasteButtonTapped_when_thereIsString() async {
        await store.send(.pasteButtonTapped) {
            $0.phoneNumber = "+551234"
            $0.isClipboardImportPromptVisible = false
            $0.lastHandledPasteboardChangeCount = 1
        }
    }

    func test_openButtonTapped_when_urlIsValid() async {
        await store.send(.openButtonTapped)

        XCTAssertEqual(urlParameters, [URL(string: "https://wa.me/55")!])
    }

    func test_openButtonTapped_sanitizesFormattingCharacters() async {
        await store.send(.set(\.phoneNumber, "+55 (11) 99999-9999")) {
            $0.phoneNumber = "+55 (11) 99999-9999"
        }

        await store.send(.openButtonTapped)

        XCTAssertEqual(urlParameters, [URL(string: "https://wa.me/5511999999999")!])
    }

    func test_openButtonTapped_ignoresWhitespaceAndSymbols() async {
        await store.send(.set(\.phoneNumber, "  +55-11 98888 7777  ")) {
            $0.phoneNumber = "  +55-11 98888 7777  "
        }

        await store.send(.openButtonTapped)

        XCTAssertEqual(urlParameters, [URL(string: "https://wa.me/5511988887777")!])
    }

    func test_openButtonTapped_whenNoDigits_doesNotOpenURL() async {
        await store.send(.set(\.phoneNumber, "()+ -")) {
            $0.phoneNumber = "()+ -"
        }

        await store.send(.openButtonTapped)

        XCTAssertEqual(urlParameters, [])
    }

    func test_openButtonTapped_whenEmptyString_doesNotOpenURL() async {
        await store.send(.set(\.phoneNumber, "")) {
            $0.phoneNumber = ""
        }

        await store.send(.openButtonTapped)

        XCTAssertEqual(urlParameters, [])
    }

    func test_textFieldSubmitted_usesSanitizedOpenBehavior() async {
        await store.send(.set(\.phoneNumber, "+55 (11) 91234-5678")) {
            $0.phoneNumber = "+55 (11) 91234-5678"
        }

        await store.send(.textFieldSubmitted)
        await store.receive(.openButtonTapped)

        XCTAssertEqual(urlParameters, [URL(string: "https://wa.me/5511912345678")!])
    }

    func test_scenePhaseUpdated() async {
        await store.send(.scenePhaseUpdated) {
            $0.isPasteEnabled = true
        }
        await store.receive(.clipboardDetectionFinished(importedValue: "+551234", changeCount: 1)) {
            $0.isClipboardImportPromptVisible = true
            $0.clipboardImportCandidate = "+551234"
        }
    }

    func test_scenePhaseUpdated_usesPasteboardHasStringProperty() async {
        pasteboardMock.string = nil
        pasteboardMock.hasString = true

        await store.send(.scenePhaseUpdated) {
            $0.isPasteEnabled = true
        }
        await store.receive(.clipboardDetectionFinished(importedValue: "+551234", changeCount: 1)) {
            $0.isClipboardImportPromptVisible = true
            $0.clipboardImportCandidate = "+551234"
        }
    }

    func test_scenePhaseUpdated_disablesPaste_whenPasteboardHasNoString() async {
        pasteboardMock.hasString = true

        await store.send(.scenePhaseUpdated) {
            $0.isPasteEnabled = true
        }
        await store.receive(.clipboardDetectionFinished(importedValue: "+551234", changeCount: 1)) {
            $0.isClipboardImportPromptVisible = true
            $0.clipboardImportCandidate = "+551234"
        }

        pasteboardMock.hasString = false
        pasteboardMock.string = "1234"
        pasteboardMock.detectedImportCandidate = nil
        pasteboardMock.changeCount = 2

        await store.send(.scenePhaseUpdated) {
            $0.isPasteEnabled = false
        }
        await store.receive(.clipboardDetectionFinished(importedValue: nil, changeCount: 2)) {
            $0.isClipboardImportPromptVisible = false
            $0.clipboardImportCandidate = nil
        }
    }

    func test_clipboardDetectionFinished_showsPromptWhenRelevant() async {
        await store.send(.clipboardDetectionFinished(importedValue: "+551234", changeCount: 1)) {
            $0.isClipboardImportPromptVisible = true
            $0.clipboardImportCandidate = "+551234"
        }
    }

    func test_clipboardPromptTapped_importsClipboardValue() async {
        await store.send(.clipboardDetectionFinished(importedValue: "+5511988887777", changeCount: 1)) {
            $0.isClipboardImportPromptVisible = true
            $0.clipboardImportCandidate = "+5511988887777"
        }

        await store.send(.clipboardImportPromptTapped) {
            $0.phoneNumber = "+5511988887777"
            $0.isClipboardImportPromptVisible = false
            $0.lastHandledPasteboardChangeCount = 1
            $0.clipboardImportCandidate = nil
        }
    }

    func test_clipboardPromptDismissed_hidesPrompt() async {
        await store.send(.clipboardDetectionFinished(importedValue: "+551234", changeCount: 1)) {
            $0.isClipboardImportPromptVisible = true
            $0.clipboardImportCandidate = "+551234"
        }

        await store.send(.clipboardImportPromptDismissed) {
            $0.isClipboardImportPromptVisible = false
            $0.lastHandledPasteboardChangeCount = 1
            $0.clipboardImportCandidate = nil
        }
    }

    func test_scenePhaseUpdated_doesNotRepeatPromptForSameClipboardAfterDismiss() async {
        await store.send(.scenePhaseUpdated) {
            $0.isPasteEnabled = true
        }
        await store.receive(.clipboardDetectionFinished(importedValue: "+551234", changeCount: 1)) {
            $0.isClipboardImportPromptVisible = true
            $0.clipboardImportCandidate = "+551234"
        }
        await store.send(.clipboardImportPromptDismissed) {
            $0.isClipboardImportPromptVisible = false
            $0.lastHandledPasteboardChangeCount = 1
            $0.clipboardImportCandidate = nil
        }
        await store.send(.scenePhaseUpdated)
        await store.receive(.clipboardDetectionFinished(importedValue: "+551234", changeCount: 1))
    }

    func test_scenePhaseUpdated_repeatsPromptWhenClipboardChanges() async {
        await store.send(.scenePhaseUpdated) {
            $0.isPasteEnabled = true
        }
        await store.receive(.clipboardDetectionFinished(importedValue: "+551234", changeCount: 1)) {
            $0.isClipboardImportPromptVisible = true
            $0.clipboardImportCandidate = "+551234"
        }
        await store.send(.clipboardImportPromptDismissed) {
            $0.isClipboardImportPromptVisible = false
            $0.lastHandledPasteboardChangeCount = 1
            $0.clipboardImportCandidate = nil
        }

        pasteboardMock.changeCount = 2

        await store.send(.scenePhaseUpdated)
        await store.receive(.clipboardDetectionFinished(importedValue: "+551234", changeCount: 2)) {
            $0.isClipboardImportPromptVisible = true
            $0.clipboardImportCandidate = "+551234"
        }
    }

    func test_clipboardDetectionFinished_hidesPromptWhenCandidateMatchesCurrentField() async {
        await store.send(.set(\.phoneNumber, "+55 (11) 98888-7777")) {
            $0.phoneNumber = "+55 (11) 98888-7777"
        }

        await store.send(.clipboardDetectionFinished(importedValue: "+5511912345678", changeCount: 1)) {
            $0.isClipboardImportPromptVisible = true
            $0.clipboardImportCandidate = "+5511912345678"
        }

        await store.send(.clipboardDetectionFinished(importedValue: "+5511988887777", changeCount: 1)) {
            $0.isClipboardImportPromptVisible = false
            $0.clipboardImportCandidate = nil
        }
    }

    func test_validationState_whenNoDigits_isInvalid() async {
        await store.send(.set(\.phoneNumber, "()- +")) {
            $0.phoneNumber = "()- +"
        }

        XCTAssertFalse(store.state.isOpenEnabled)
        XCTAssertTrue(store.state.shouldShowValidationError)
    }

    func test_validationState_whenFormattedDigits_isValid() async {
        await store.send(.set(\.phoneNumber, "+55 (11) 90000-0000")) {
            $0.phoneNumber = "+55 (11) 90000-0000"
        }

        XCTAssertTrue(store.state.isOpenEnabled)
        XCTAssertFalse(store.state.shouldShowValidationError)
    }
}
