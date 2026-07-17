enum AppSection: CaseIterable, Hashable, Identifiable, Sendable {
    case tools
    case saved
    case settings

    var id: Self { self }
}

enum AppDestination: Hashable, Identifiable, Sendable {
    case visualTimer

    var id: Self { self }
}

enum AppNavigationLayout: Equatable, Sendable {
    case compactTabs
    case regularSplit
}

enum AppDeviceFamily: Equatable, Sendable {
    case phone
    case pad
    case other
}

enum AppHorizontalSize: Equatable, Sendable {
    case compact
    case regular
    case unspecified
}

enum AppNavigationLayoutResolver {
    static func resolve(
        deviceFamily: AppDeviceFamily,
        horizontalSize: AppHorizontalSize,
        forcesCompactNavigation: Bool
    ) -> AppNavigationLayout {
        guard
            !forcesCompactNavigation,
            deviceFamily == .pad,
            horizontalSize == .regular
        else {
            return .compactTabs
        }

        return .regularSplit
    }
}

struct AppNavigationState: Equatable, Sendable {
    var selectedSection = AppSection.tools
    var selectedDestination: AppDestination?
    var childFacingDestination: AppDestination?

    var compactToolsPath: [AppDestination] {
        get {
            selectedDestination.map { [$0] } ?? []
        }
        set {
            selectedDestination = newValue.last
            if selectedDestination != nil {
                selectedSection = .tools
            }
        }
    }

    mutating func select(section: AppSection) {
        selectedSection = section
    }

    mutating func show(_ destination: AppDestination) {
        selectedSection = .tools
        selectedDestination = destination
    }

    mutating func presentChildFacing(_ destination: AppDestination) {
        show(destination)
        childFacingDestination = destination
    }

    mutating func dismissChildFacing() {
        childFacingDestination = nil
    }
}
