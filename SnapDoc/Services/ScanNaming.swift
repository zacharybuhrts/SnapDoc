import Foundation

enum ScanNaming {
    static let maxLength = 80

    /// Trims, collapses whitespace, and drops control characters.
    /// Returns nil when the result would be empty.
    static func cleaned(_ raw: String) -> String? {
        let scalars = raw.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }
        let stripped = String(String.UnicodeScalarView(scalars))
        let collapsed = stripped.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard !collapsed.isEmpty else { return nil }
        if collapsed.count <= maxLength {
            return collapsed
        }
        return String(collapsed.prefix(maxLength))
    }

    static func defaultTitle(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "MMM d, yyyy, h:mm a"
        return "Scan \(formatter.string(from: date))"
    }
}
