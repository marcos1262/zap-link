import UIKit
import Dependencies

protocol PasteboardProtocol {
    var string: String? { get }
    var hasString: Bool { get }
    var changeCount: Int { get }
    func detectImportCandidate() async -> String?
}

extension PasteboardProtocol {
    var hasString: Bool {
        string?.isEmpty == false
    }

    var changeCount: Int {
        0
    }

    func detectImportCandidate() async -> String? {
        string.flatMap { LinkImportParser.importedPhoneFieldValue(from: $0) }
    }
}

extension UIPasteboard: PasteboardProtocol {
    var hasString: Bool {
        hasStrings
    }

    func detectImportCandidate() async -> String? {
        let keyPaths: Set<PartialKeyPath<UIPasteboard.DetectedValues>> = [
            \.phoneNumbers,
            \.links,
            \.probableWebURL
        ]

        do {
            let detected = try await detectedValues(for: keyPaths)

            if let phoneNumber = detected.phoneNumbers.first?.phoneNumber {
                return LinkImportParser.importedPhoneFieldValue(from: phoneNumber)
            }

            if let link = detected.links.first?.url.absoluteString {
                return LinkImportParser.importedPhoneFieldValue(from: link)
            }

            let probableWebURL = detected.probableWebURL
            if probableWebURL.isEmpty == false {
                return LinkImportParser.importedPhoneFieldValue(from: probableWebURL)
            }

            return nil
        } catch {
            return string.flatMap { LinkImportParser.importedPhoneFieldValue(from: $0) }
        }
    }
}

enum PasteboardKey: DependencyKey {
    static let liveValue: any PasteboardProtocol = UIPasteboard.general
    static let testValue: any PasteboardProtocol = TestPasteboard()

    private struct TestPasteboard: PasteboardProtocol {
        var string: String? { nil }
        var hasString: Bool { false }
        var changeCount: Int { 0 }
        func detectImportCandidate() async -> String? { nil }
    }
}

extension DependencyValues {
    var pasteboard: any PasteboardProtocol {
        get { self[PasteboardKey.self] }
        set { self[PasteboardKey.self] = newValue }
    }
}
