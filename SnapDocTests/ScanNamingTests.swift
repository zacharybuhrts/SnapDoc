import XCTest
@testable import SnapDoc

final class ScanNamingTests: XCTestCase {
    func testCleansWhitespaceAndControlCharacters() {
        let cleaned = ScanNaming.cleaned("  Café \n  scan\t ")
        XCTAssertEqual(cleaned, "Café scan")
        XCTAssertNil(ScanNaming.cleaned("   \n\t  "))
        XCTAssertNil(ScanNaming.cleaned(""))
    }

    func testLimitsLength() {
        let long = String(repeating: "a", count: 120)
        let cleaned = ScanNaming.cleaned(long)
        XCTAssertEqual(cleaned?.count, ScanNaming.maxLength)
    }

    func testDefaultTitleUsesAFixedClock() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let title = ScanNaming.defaultTitle(for: date, timeZone: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual(title, "Scan Nov 14, 2023, 10:13 PM")
    }
}
