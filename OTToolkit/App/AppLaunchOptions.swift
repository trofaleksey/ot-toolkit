struct AppLaunchOptions: Equatable, Sendable {
    static let disableAnimationsArgument = "-disable-animations"
    static let largestAccessibilityTextArgument = "-ui-test-largest-accessibility-text"

    let disablesAnimations: Bool
    let usesLargestAccessibilityText: Bool

    init(arguments: [String]) {
        disablesAnimations = arguments.contains(Self.disableAnimationsArgument)
        usesLargestAccessibilityText = arguments.contains(Self.largestAccessibilityTextArgument)
    }
}
