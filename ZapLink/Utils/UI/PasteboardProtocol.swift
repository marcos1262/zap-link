import UIKit
import Dependencies

protocol PasteboardProtocol {
    var string: String? { get }
    var hasString: Bool { get }
}

extension PasteboardProtocol {
    var hasString: Bool {
        string?.isEmpty == false
    }
}

extension UIPasteboard: PasteboardProtocol {
    var hasString: Bool {
        hasStrings
    }
}

enum PasteboardKey: DependencyKey {
    static let liveValue: any PasteboardProtocol = UIPasteboard()
}

extension DependencyValues {
    var pasteboard: any PasteboardProtocol {
        get { self[PasteboardKey.self] }
        set { self[PasteboardKey.self] = newValue }
    }
}
