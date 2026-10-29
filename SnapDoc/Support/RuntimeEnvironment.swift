import Foundation

enum RuntimeEnvironment {
    /// True when the app process was launched by an XCTest bundle.
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
