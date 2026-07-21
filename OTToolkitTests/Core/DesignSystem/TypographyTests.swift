import SwiftUI
import XCTest
@testable import OTToolkit

final class TypographyTests: XCTestCase {
    func testTokensMapToTheDocumentedSemanticTextStyles() {
        XCTAssertEqual(OTTypography.metadata, .caption)
        XCTAssertEqual(OTTypography.controlLabel, .callout)
        XCTAssertEqual(OTTypography.body, .body)
        XCTAssertEqual(OTTypography.sectionHeading, .headline)
        XCTAssertEqual(OTTypography.screenTitle, .title)
    }

    func testChildFacingValueUsesAnEmphasizedLargeTitle() {
        XCTAssertEqual(OTTypography.childFacingValue, .largeTitle.bold())
        XCTAssertNotEqual(OTTypography.childFacingValue, .largeTitle)
    }
}
