import Foundation
import SwiftData
import SwiftUI

@main
struct OTToolkitApp: App {
    private let launchOptions: AppLaunchOptions
    @State private var dataController: AppDataController

    init() {
        let options = AppLaunchOptions(arguments: ProcessInfo.processInfo.arguments)
        launchOptions = options
        _dataController = State(
            initialValue: AppDataController(usesInMemoryStore: options.usesInMemoryStore)
        )
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
        if let modelContext = dataController.modelContainer?.mainContext {
            if launchOptions.usesLargestAccessibilityText {
                AppSceneRootView(
                    launchOptions: launchOptions,
                    modelContext: modelContext
                )
                .dynamicTypeSize(.accessibility5)
            } else {
                AppSceneRootView(
                    launchOptions: launchOptions,
                    modelContext: modelContext
                )
            }
        } else {
            PersistenceRecoveryView(controller: dataController)
        }
    }
}
