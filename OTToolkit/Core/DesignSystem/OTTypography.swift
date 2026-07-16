import SwiftUI

enum OTTypography {
    static var metadata: Font { .caption }
    static var controlLabel: Font { .callout }
    static var body: Font { .body }
    static var sectionHeading: Font { .headline }
    static var screenTitle: Font { .title }
    static var childFacingValue: Font { .largeTitle.bold() }
}
