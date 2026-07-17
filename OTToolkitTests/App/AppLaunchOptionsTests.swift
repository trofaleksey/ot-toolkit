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

    func testPositiveTimerDurationOverrideIsRecognized() {
        let options = AppLaunchOptions(
            arguments: ["OTToolkit", "-ui-test-timer-duration-seconds", "2"]
        )

        XCTAssertEqual(options.timerDurationOverrideSeconds, 2)
    }

    func testInvalidTimerDurationOverridesAreIgnored() {
        let missingValue = AppLaunchOptions(
            arguments: ["OTToolkit", "-ui-test-timer-duration-seconds"]
        )
        let zeroValue = AppLaunchOptions(
            arguments: ["OTToolkit", "-ui-test-timer-duration-seconds", "0"]
        )
        let nonnumericValue = AppLaunchOptions(
            arguments: ["OTToolkit", "-ui-test-timer-duration-seconds", "soon"]
        )

        XCTAssertNil(missingValue.timerDurationOverrideSeconds)
        XCTAssertNil(zeroValue.timerDurationOverrideSeconds)
        XCTAssertNil(nonnumericValue.timerDurationOverrideSeconds)
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
        XCTAssertNil(options.timerDurationOverrideSeconds)
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
