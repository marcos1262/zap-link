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

    func test_initialState() {
        XCTAssertEqual(store.state, PhoneFeature.State(phoneNumber: "+55",
                                                       isPasteEnabled: false))
    }

    func test_setBinding() async {
        await store.send(.set(\.phoneNumber, "123")) {
            $0.phoneNumber = "123"
        }
    }

    func test_textFieldSubmitted() async {
        await store.send(.textFieldSubmitted)

        await store.receive(.openButtonTapped)

        XCTAssertEqual(urlParameters, [URL(string: "https://wa.me/+55")])
    }

    func test_pasteButtonTapped_when_stringIsNil() async {
        pasteboardMock.string = nil

        await store.send(.pasteButtonTapped)
    }

    func test_pasteButtonTapped_when_thereIsString() async {
        await store.send(.pasteButtonTapped) {
            $0.phoneNumber = "+551234"
        }
    }

    func test_openButtonTapped_when_urlIsValid() async {
        await store.send(.openButtonTapped)

        XCTAssertEqual(urlParameters, [URL(string: "https://wa.me/+55")])
    }

    func test_scenePhaseUpdated() async {
        await store.send(.scenePhaseUpdated) {
            $0.isPasteEnabled = true
        }
    }
}
