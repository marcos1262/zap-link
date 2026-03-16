import XCTest

@testable import ZapLink

final class LinkImportParserTests: XCTestCase {
    func test_extractFirstCandidate_fromPlainPhoneText() {
        let candidate = LinkImportParser.extractFirstCandidate(from: "Falar com (11) 91234-5678 hoje")

        XCTAssertEqual(candidate?.normalizedDigits, "11912345678")
        XCTAssertEqual(candidate?.source, .phoneNumber)
    }

    func test_extractFirstCandidate_fromWhatsAppURL() {
        let candidate = LinkImportParser.extractFirstCandidate(from: URL(string: "https://wa.me/5511912345678")!)

        XCTAssertEqual(candidate?.normalizedDigits, "5511912345678")
        XCTAssertEqual(candidate?.source, .url)
    }

    func test_extractFirstCandidate_fromTelURL() {
        let candidate = LinkImportParser.extractFirstCandidate(from: URL(string: "tel:+55-11-91234-5678")!)

        XCTAssertEqual(candidate?.normalizedDigits, "5511912345678")
        XCTAssertEqual(candidate?.source, .url)
    }

    func test_extractFirstCandidate_picksFirstMatch() {
        let text = "Primeiro 11 98888-7777 depois 11 97777-6666"

        let candidate = LinkImportParser.extractFirstCandidate(from: text)

        XCTAssertEqual(candidate?.normalizedDigits, "11988887777")
    }

    func test_extractFirstCandidate_returnsNilWhenNoDigits() {
        XCTAssertNil(LinkImportParser.extractFirstCandidate(from: "sem telefone aqui"))
    }

    func test_importedPhoneFieldValue_forPlainTextPrefixesDefaultCountryCode() {
        XCTAssertEqual(LinkImportParser.importedPhoneFieldValue(from: "11988887777"), "+5511988887777")
    }

    func test_importedPhoneFieldValue_forURLUsesExtractedDigitsWithoutDoubleCountryCode() {
        XCTAssertEqual(
            LinkImportParser.importedPhoneFieldValue(from: "https://wa.me/5511988887777"),
            "+5511988887777"
        )
    }

    func test_importedPhoneFieldValue_forWhatsAppURLWithQueryIgnoresQueryDigits() {
        XCTAssertEqual(
            LinkImportParser.importedPhoneFieldValue(from: "https://wa.me/5511988887777?text=Oi%202025"),
            "+5511988887777"
        )
    }

    func test_importedPhoneFieldValue_forEmbeddedInternationalNumberKeepsCountryCode() {
        XCTAssertEqual(
            LinkImportParser.importedPhoneFieldValue(from: "Contato: +1 415 555 1212"),
            "+14155551212"
        )
    }
}
