import Foundation
import SwiftUI

@main
struct OTToolkitApp: App {
    private let launchOptions: AppLaunchOptions

    init() {
        launchOptions = AppLaunchOptions(arguments: ProcessInfo.processInfo.arguments)
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .transaction { transaction in
                    if launchOptions.disablesAnimations {
                        transaction.animation = nil
                        transaction.disablesAnimations = true
                    }
                }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if launchOptions.usesLargestAccessibilityText {
            AppSceneRootView(launchOptions: launchOptions)
                .dynamicTypeSize(.accessibility5)
        } else {
            AppSceneRootView(launchOptions: launchOptions)
        }
    }
}
