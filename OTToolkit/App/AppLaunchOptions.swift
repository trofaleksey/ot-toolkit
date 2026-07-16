struct AppLaunchOptions: Equatable, Sendable {
    static let disableAnimationsArgument = "-disable-animations"
    static let forceCompactNavigationArgument = "-ui-test-force-compact-navigation"
    static let enableLayoutToggleFixtureArgument = "-ui-test-enable-layout-toggle-fixture"
    static let forcePrivacyCoverArgument = "-ui-test-force-privacy-cover"
    static let largestAccessibilityTextArgument = "-ui-test-largest-accessibility-text"
    static let startChildFacingFixtureArgument = "-ui-test-start-child-facing-fixture"

    let disablesAnimations: Bool
    let forcesCompactNavigation: Bool
    let enablesLayoutToggleFixture: Bool
    let forcesPrivacyCover: Bool
    let usesLargestAccessibilityText: Bool
    let startsInChildFacingFixture: Bool

    init(arguments: [String]) {
        disablesAnimations = arguments.contains(Self.disableAnimationsArgument)
        forcesCompactNavigation = arguments.contains(Self.forceCompactNavigationArgument)
        enablesLayoutToggleFixture = arguments.contains(Self.enableLayoutToggleFixtureArgument)
        forcesPrivacyCover = arguments.contains(Self.forcePrivacyCoverArgument)
        usesLargestAccessibilityText = arguments.contains(Self.largestAccessibilityTextArgument)
        startsInChildFacingFixture = arguments.contains(Self.startChildFacingFixtureArgument)
    }
}
