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

    func testAdaptiveShellUITestArgumentsAreRecognized() {
        let options = AppLaunchOptions(
            arguments: [
                "OTToolkit",
                "-ui-test-force-compact-navigation",
                "-ui-test-enable-layout-toggle-fixture",
                "-ui-test-force-privacy-cover",
                "-ui-test-start-child-facing-fixture",
            ]
        )

        XCTAssertTrue(options.forcesCompactNavigation)
        XCTAssertTrue(options.enablesLayoutToggleFixture)
        XCTAssertTrue(options.forcesPrivacyCover)
        XCTAssertTrue(options.startsInChildFacingFixture)
    }

    func testDisableAnimationsArgumentRequiresAnExactMatch() {
        let options = AppLaunchOptions(arguments: ["OTToolkit", "--disable-animations"])

        XCTAssertFalse(options.disablesAnimations)
    }

    func testAccessibilityOverridesRemainDisabledByDefault() {
        let options = AppLaunchOptions(arguments: ["OTToolkit"])

        XCTAssertFalse(options.usesLargestAccessibilityText)
        XCTAssertFalse(options.forcesCompactNavigation)
        XCTAssertFalse(options.enablesLayoutToggleFixture)
        XCTAssertFalse(options.forcesPrivacyCover)
        XCTAssertFalse(options.startsInChildFacingFixture)
    }

    func testAdaptiveShellUITestArgumentsRequireExactMatches() {
        let options = AppLaunchOptions(
            arguments: [
                "OTToolkit",
                "--ui-test-force-compact-navigation",
                "--ui-test-enable-layout-toggle-fixture",
                "--ui-test-force-privacy-cover",
                "--ui-test-start-child-facing-fixture",
            ]
        )

        XCTAssertFalse(options.forcesCompactNavigation)
        XCTAssertFalse(options.enablesLayoutToggleFixture)
        XCTAssertFalse(options.forcesPrivacyCover)
        XCTAssertFalse(options.startsInChildFacingFixture)
    }
}
