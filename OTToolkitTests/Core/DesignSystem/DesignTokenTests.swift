import SwiftUI
import XCTest
@testable import OTToolkit

final class DesignTokenTests: XCTestCase {
    func testSpacingUsesTheDocumentedFourPointGrid() {
        XCTAssertEqual(OTSpacing.xs, 4)
        XCTAssertEqual(OTSpacing.sm, 8)
        XCTAssertEqual(OTSpacing.md, 16)
        XCTAssertEqual(OTSpacing.lg, 24)
        XCTAssertEqual(OTSpacing.xl, 32)
    }

    func testCornerRadiiMatchTheDocumentedShapeRoles() {
        XCTAssertEqual(OTRadius.control, 12)
        XCTAssertEqual(OTRadius.card, 16)
    }

    @MainActor
    func testMinimumInteractiveSizeModifierProvidesAtLeastFortyFourPoints() {
        let controller = UIHostingController(
            rootView: Button("Example") {}
                .otMinimumInteractiveSize()
        )

        let size = controller.sizeThatFits(in: CGSize(width: 320, height: 320))

        XCTAssertGreaterThanOrEqual(size.width, OTControlMetrics.minimumInteractiveDimension)
        XCTAssertGreaterThanOrEqual(size.height, OTControlMetrics.minimumInteractiveDimension)
    }
}
