import XCTest
@testable import OTToolkit

final class AccessibilityPreferencesTests: XCTestCase {
    func testStandardPreferencesAllowMotionAndUseStandardBoundary() {
        let preferences = OTAccessibilityPreferences(
            reducesMotion: false,
            increasesContrast: false,
            differentiatesWithoutColor: false,
            reducesTransparency: false
        )

        XCTAssertTrue(preferences.allowsNonessentialMotion)
        XCTAssertEqual(preferences.boundaryLineWidth, 1)
    }

    func testReduceMotionDisablesNonessentialMotion() {
        let preferences = OTAccessibilityPreferences(
            reducesMotion: true,
            increasesContrast: false,
            differentiatesWithoutColor: false,
            reducesTransparency: false
        )

        XCTAssertFalse(preferences.allowsNonessentialMotion)
    }

    func testIncreaseContrastStrengthensBoundaries() {
        let preferences = OTAccessibilityPreferences(
            reducesMotion: false,
            increasesContrast: true,
            differentiatesWithoutColor: false,
            reducesTransparency: false
        )

        XCTAssertEqual(preferences.boundaryLineWidth, 2)
    }

    func testNonColorAndTransparencyPreferencesRemainAvailableToViews() {
        let preferences = OTAccessibilityPreferences(
            reducesMotion: false,
            increasesContrast: false,
            differentiatesWithoutColor: true,
            reducesTransparency: true
        )

        XCTAssertTrue(preferences.differentiatesWithoutColor)
        XCTAssertTrue(preferences.reducesTransparency)
    }
}
