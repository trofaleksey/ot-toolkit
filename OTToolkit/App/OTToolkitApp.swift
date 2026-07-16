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
            HomeView()
                .transaction { transaction in
                    if launchOptions.disablesAnimations {
                        transaction.animation = nil
                        transaction.disablesAnimations = true
                    }
                }
        }
    }
}
