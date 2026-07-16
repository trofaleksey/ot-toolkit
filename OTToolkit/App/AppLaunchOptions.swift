struct AppLaunchOptions: Equatable, Sendable {
    static let disableAnimationsArgument = "-disable-animations"

    let disablesAnimations: Bool

    init(arguments: [String]) {
        disablesAnimations = arguments.contains(Self.disableAnimationsArgument)
    }
}
