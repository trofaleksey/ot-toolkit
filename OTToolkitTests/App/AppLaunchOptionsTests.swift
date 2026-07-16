import XCTest
@testable import OTToolkit

final class AppLaunchOptionsTests: XCTestCase {
    func testAnimationsRemainEnabledByDefault() {
        let options = AppLaunchOptions(arguments: ["OTToolkit"])

        XCTAssertFalse(options.disablesAnimations)
    }

    func testDisableAnimationsArgumentIsRecognized() {
        let options = AppLaunchOptions(arguments: ["OTToolkit", "-disable-animations"])

        XCTAssertTrue(options.disablesAnimations)
    }

    func testDisableAnimationsArgumentRequiresAnExactMatch() {
        let options = AppLaunchOptions(arguments: ["OTToolkit", "--disable-animations"])

        XCTAssertFalse(options.disablesAnimations)
    }
}
