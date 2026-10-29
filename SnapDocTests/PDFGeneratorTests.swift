import PDFKit
import XCTest
@testable import SnapDoc

final class PDFGeneratorTests: XCTestCase {
    func testEmptyInputThrows() {
        XCTAssertThrowsError(try PDFGenerator.makePDF(from: [])) { error in
            XCTAssertEqual(error as? PDFGeneratorError, .noPages)
        }
    }

    func testMultiPagePDFMatchesImages() throws {
        let images = [
            TestImages.solid(width: 20, height: 40, red: 255, green: 255, blue: 255),
            TestImages.solid(width: 30, height: 18, red: 0, green: 0, blue: 0)
        ]
        let data = try PDFGenerator.makePDF(from: images)
        XCTAssertTrue(data.starts(with: Data("%PDF".utf8)))
        let document = try XCTUnwrap(PDFDocument(data: data))
        XCTAssertEqual(document.pageCount, 2)

        let first = try XCTUnwrap(document.page(at: 0))
        let second = try XCTUnwrap(document.page(at: 1))
        XCTAssertEqual(first.bounds(for: .mediaBox).width, 20, accuracy: 0.5)
        XCTAssertEqual(first.bounds(for: .mediaBox).height, 40, accuracy: 0.5)
        XCTAssertEqual(second.bounds(for: .mediaBox).width, 30, accuracy: 0.5)
        XCTAssertEqual(second.bounds(for: .mediaBox).height, 18, accuracy: 0.5)
    }
}
