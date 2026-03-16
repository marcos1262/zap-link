import Foundation

struct LinkImportParser {
    struct ImportCandidate: Equatable {
        enum Source: Equatable {
            case text
            case phoneNumber
            case url
        }

        let rawValue: String
        let normalizedDigits: String
        let source: Source
    }

    private static let detector: NSDataDetector? = {
        try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue |
                            NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
    }()

    static func sanitizedDigits(from rawInput: String) -> String {
        let digits = rawInput.unicodeScalars.filter { scalar in
            (48...57).contains(scalar.value)
        }
        return String(String.UnicodeScalarView(digits))
    }

    static func whatsAppURL(from rawInput: String) -> URL? {
        let digits = sanitizedDigits(from: rawInput)
        guard !digits.isEmpty else { return nil }
        return URL(string: "https://wa.me/" + digits)
    }

    static func extractFirstCandidate(from url: URL) -> ImportCandidate? {
        for rawValue in urlCandidateRawValues(from: url) {
            if let candidate = buildCandidate(rawValue: rawValue, source: .url) {
                return candidate
            }
        }

        return nil
    }

    static func extractFirstCandidate(from text: String) -> ImportCandidate? {
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)

        if let detector {
            let matches = detector.matches(in: text, options: [], range: nsRange)
            for match in matches {
                if let url = match.url,
                   let candidate = extractFirstCandidate(from: url) {
                    return candidate
                }

                if let phoneNumber = match.phoneNumber,
                   let candidate = buildCandidate(rawValue: phoneNumber, source: .phoneNumber) {
                    return candidate
                }

                if let range = Range(match.range, in: text) {
                    let substring = String(text[range])
                    if let candidate = buildCandidate(rawValue: substring, source: .text) {
                        return candidate
                    }
                }
            }
        }

        return buildCandidate(rawValue: text, source: .text)
    }

    static func importedPhoneFieldValue(from rawInput: String,
                                        defaultCountryCode: String = "+55") -> String? {
        guard let candidate = extractFirstCandidate(from: rawInput) else { return nil }
        return importedPhoneFieldValue(from: candidate, defaultCountryCode: defaultCountryCode)
    }

    static func importedPhoneFieldValue(from candidate: ImportCandidate,
                                        defaultCountryCode: String = "+55") -> String {
        switch candidate.source {
        case .url:
            return "+" + candidate.normalizedDigits
        case .phoneNumber, .text:
            let trimmed = candidate.rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("+") {
                return "+" + candidate.normalizedDigits
            }
            return defaultCountryCode + candidate.normalizedDigits
        }
    }

    private static func buildCandidate(rawValue: String, source: ImportCandidate.Source) -> ImportCandidate? {
        let digits = sanitizedDigits(from: rawValue)
        guard !digits.isEmpty else { return nil }
        return ImportCandidate(rawValue: rawValue, normalizedDigits: digits, source: source)
    }

    private static func urlCandidateRawValues(from url: URL) -> [String] {
        var values: [String] = []

        if url.scheme?.lowercased() == "tel" {
            let telString = url.absoluteString.replacingOccurrences(of: "tel:", with: "", options: [.caseInsensitive, .anchored])
            values.append(telString.removingPercentEncoding ?? telString)
        }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let phoneQueryValue = components.queryItems?.first(where: {
                let name = $0.name.lowercased()
                return name == "phone" || name == "phonenumber" || name == "number"
            })?.value {
                values.append(phoneQueryValue)
            }

            let pathComponents = components.path
                .split(separator: "/")
                .map(String.init)
                .filter { !$0.isEmpty }

            values.append(contentsOf: pathComponents)
        } else {
            let pathComponents = url.path
                .split(separator: "/")
                .map(String.init)
                .filter { !$0.isEmpty }

            values.append(contentsOf: pathComponents)
        }

        return values
    }
}
