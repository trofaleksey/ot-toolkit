import SwiftUI

struct OTAccessibilityPreferences: Equatable, Sendable {
    let reducesMotion: Bool
    let increasesContrast: Bool
    let differentiatesWithoutColor: Bool
    let reducesTransparency: Bool

    var allowsNonessentialMotion: Bool {
        !reducesMotion
    }

    var boundaryLineWidth: CGFloat {
        increasesContrast ? 2 : 1
    }
}

extension EnvironmentValues {
    var otAccessibilityPreferences: OTAccessibilityPreferences {
        OTAccessibilityPreferences(
            reducesMotion: accessibilityReduceMotion,
            increasesContrast: colorSchemeContrast == .increased,
            differentiatesWithoutColor: accessibilityDifferentiateWithoutColor,
            reducesTransparency: accessibilityReduceTransparency
        )
    }
}
