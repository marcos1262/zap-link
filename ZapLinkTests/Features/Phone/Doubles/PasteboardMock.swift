@testable import ZapLink

final class PasteboardMock: PasteboardProtocol {
    var string: String? = "1234"
    var hasString: Bool = true
    var changeCount: Int = 1
    var detectedImportCandidate: String? = "+551234"

    func detectImportCandidate() async -> String? {
        detectedImportCandidate
    }
}
