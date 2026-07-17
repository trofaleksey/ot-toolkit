import XCTest
@testable import OTToolkit

final class AppNavigationStateTests: XCTestCase {
    func testNavigationStartsOnToolsWithoutAnActiveDestination() {
        let navigation = AppNavigationState()

        XCTAssertEqual(navigation.selectedSection, .tools)
        XCTAssertNil(navigation.selectedDestination)
        XCTAssertNil(navigation.childFacingDestination)
        XCTAssertTrue(navigation.compactToolsPath.isEmpty)
    }

    func testOnlyRegularWidthIPadUsesSplitNavigation() {
        XCTAssertEqual(
            AppNavigationLayoutResolver.resolve(
                deviceFamily: .pad,
                horizontalSize: .regular,
                forcesCompactNavigation: false
            ),
            .regularSplit
        )

        for deviceFamily in [AppDeviceFamily.phone, .other] {
            XCTAssertEqual(
                AppNavigationLayoutResolver.resolve(
                    deviceFamily: deviceFamily,
                    horizontalSize: .regular,
                    forcesCompactNavigation: false
                ),
                .compactTabs
            )
        }

        for horizontalSize in [AppHorizontalSize.compact, .unspecified] {
            XCTAssertEqual(
                AppNavigationLayoutResolver.resolve(
                    deviceFamily: .pad,
                    horizontalSize: horizontalSize,
                    forcesCompactNavigation: false
                ),
                .compactTabs
            )
        }
    }

    func testCompactNavigationOverrideWinsOnRegularIPad() {
        XCTAssertEqual(
            AppNavigationLayoutResolver.resolve(
                deviceFamily: .pad,
                horizontalSize: .regular,
                forcesCompactNavigation: true
            ),
            .compactTabs
        )
    }

    func testShowingToolSynchronizesSplitSelectionAndCompactPath() {
        var navigation = AppNavigationState()
        navigation.select(section: .settings)

        navigation.show(.visualTimer)

        XCTAssertEqual(navigation.selectedSection, .tools)
        XCTAssertEqual(navigation.selectedDestination, .visualTimer)
        XCTAssertEqual(navigation.compactToolsPath, [.visualTimer])
    }

    func testCompactBackNavigationClearsTheSharedDestination() {
        var navigation = AppNavigationState()
        navigation.show(.visualTimer)

        navigation.compactToolsPath = []

        XCTAssertNil(navigation.selectedDestination)
        XCTAssertTrue(navigation.compactToolsPath.isEmpty)
    }

    func testSwitchingSectionsPreservesActiveToolRoute() {
        var navigation = AppNavigationState()
        navigation.show(.visualTimer)

        navigation.select(section: .saved)
        navigation.select(section: .settings)
        navigation.select(section: .tools)

        XCTAssertEqual(navigation.selectedDestination, .visualTimer)
        XCTAssertEqual(navigation.compactToolsPath, [.visualTimer])
    }

    func testAdultExitPreservesTheUnderlyingTherapistDestination() {
        var navigation = AppNavigationState()
        navigation.presentChildFacing(.visualTimer)

        navigation.dismissChildFacing()

        XCTAssertNil(navigation.childFacingDestination)
        XCTAssertEqual(navigation.selectedSection, .tools)
        XCTAssertEqual(navigation.selectedDestination, .visualTimer)
    }

    func testPrivacyCoverPolicyFailsClosedAndHonorsTestOverride() {
        XCTAssertFalse(
            AppPrivacyCoverPolicy.isCoverRequired(isSceneActive: true, isForced: false)
        )
        XCTAssertTrue(
            AppPrivacyCoverPolicy.isCoverRequired(isSceneActive: false, isForced: false)
        )
        XCTAssertTrue(
            AppPrivacyCoverPolicy.isCoverRequired(isSceneActive: true, isForced: true)
        )
        XCTAssertTrue(
            AppPrivacyCoverPolicy.isCoverRequired(isSceneActive: false, isForced: true)
        )
    }
}
