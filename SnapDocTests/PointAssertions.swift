import Foundation
import XCTest

func XCTAssertPointEqual(
    _ actual: CGPoint,
    _ expected: CGPoint,
    accuracy: CGFloat = 0.001,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(actual.x, expected.x, accuracy: accuracy, file: file, line: line)
    XCTAssertEqual(actual.y, expected.y, accuracy: accuracy, file: file, line: line)
}
