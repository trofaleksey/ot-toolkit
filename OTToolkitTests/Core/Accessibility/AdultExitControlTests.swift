import SwiftUI
import XCTest
@testable import OTToolkit

final class AdultExitControlTests: XCTestCase {
    @MainActor
    func testForwardsTheProvidedExitAction() {
        var requestedExit = false
        let control = OTAdultExitControl { requestedExit = true }

        control.onRequestExit()

        XCTAssertTrue(requestedExit)
    }

    @MainActor
    func testControlProvidesAtLeastFortyFourPointsOfInteractiveSize() {
        let controller = UIHostingController(rootView: OTAdultExitControl {})

        let size = controller.sizeThatFits(in: CGSize(width: 320, height: 320))

        XCTAssertGreaterThanOrEqual(size.width, OTControlMetrics.minimumInteractiveDimension)
        XCTAssertGreaterThanOrEqual(size.height, OTControlMetrics.minimumInteractiveDimension)
    }
}
