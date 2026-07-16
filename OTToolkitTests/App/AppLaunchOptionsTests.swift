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

    func testLargestAccessibilityTextArgumentIsRecognized() {
        let options = AppLaunchOptions(
            arguments: ["OTToolkit", "-ui-test-largest-accessibility-text"]
        )

        XCTAssertTrue(options.usesLargestAccessibilityText)
    }

    func testDisableAnimationsArgumentRequiresAnExactMatch() {
        let options = AppLaunchOptions(arguments: ["OTToolkit", "--disable-animations"])

        XCTAssertFalse(options.disablesAnimations)
    }

    func testAccessibilityOverridesRemainDisabledByDefault() {
        let options = AppLaunchOptions(arguments: ["OTToolkit"])

        XCTAssertFalse(options.usesLargestAccessibilityText)
    }
}
