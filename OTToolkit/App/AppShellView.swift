import SwiftUI
import UIKit

struct AppSceneRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var navigation: AppNavigationState
    @State private var visualTimerController: VisualTimerController
    @State private var visualTimerRuntimeCoordinator: VisualTimerRuntimeCoordinator
    @State private var fixtureForcesCompactNavigation = false

    private let launchOptions: AppLaunchOptions

    init(launchOptions: AppLaunchOptions) {
        self.launchOptions = launchOptions

        var initialNavigation = AppNavigationState()
        if launchOptions.startsInChildFacingFixture {
            initialNavigation.presentChildFacing(.visualTimer)
        }
        _navigation = State(initialValue: initialNavigation)
        _visualTimerController = State(
            initialValue: VisualTimerController(
                startDurationOverride: launchOptions.timerDurationOverrideSeconds.map {
                    .seconds($0)
                }
            )
        )
        _visualTimerRuntimeCoordinator = State(
            initialValue: VisualTimerRuntimeCoordinator()
        )
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            appShell
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VisualTimerBanner(
                        controller: visualTimerController,
                        isTimerPresented: isVisualTimerPresented
                    ) {
                        navigation.show(.visualTimer)
                    }
                }
                .disabled(isTherapistShellSuppressed)
                .allowsHitTesting(!isTherapistShellSuppressed)
                .accessibilityHidden(isTherapistShellSuppressed)
                .opacity(isTherapistShellSuppressed ? 0 : 1)

            if navigation.childFacingDestination != nil {
                ChildFacingContainer {
                    navigation.dismissChildFacing()
                } content: {
                    childFacingContent
                }
                .disabled(isPrivacyCoverRequired)
                .allowsHitTesting(!isPrivacyCoverRequired)
                .accessibilityHidden(isPrivacyCoverRequired)
                .opacity(isPrivacyCoverRequired ? 0 : 1)
                .zIndex(1)
            }

            if isPrivacyCoverRequired {
                PrivacyCoverView()
                    .zIndex(2)
            }

            if launchOptions.enablesLayoutToggleFixture, !isTherapistShellSuppressed {
                Button {
                    fixtureForcesCompactNavigation.toggle()
                } label: {
                    Text(verbatim: "Toggle layout")
                }
                .buttonStyle(.borderedProminent)
                .otMinimumInteractiveSize()
                .accessibilityIdentifier("ui-test.navigation.layout.toggle")
                .padding(OTSpacing.sm)
                .zIndex(3)
            }
        }
        .background {
            VisualTimerTimelineDriver(controller: visualTimerController) {
                synchronizeVisualTimerRuntime()
            }
        }
        .animation(nil, value: isPrivacyCoverRequired)
        .onAppear {
            synchronizeVisualTimerRuntime()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                visualTimerController.refresh()
            }
            synchronizeVisualTimerRuntime()
        }
        .onChange(of: isVisualTimerPresented) {
            synchronizeVisualTimerRuntime()
        }
        .onDisappear {
            visualTimerRuntimeCoordinator.stop()
        }
    }

    private var isTherapistShellSuppressed: Bool {
        isPrivacyCoverRequired || navigation.childFacingDestination != nil
    }

    private var isPrivacyCoverRequired: Bool {
        AppPrivacyCoverPolicy.isCoverRequired(
            isSceneActive: scenePhase == .active,
            isForced: launchOptions.forcesPrivacyCover
        )
    }

    private var isVisualTimerPresented: Bool {
        navigation.childFacingDestination == .visualTimer
            || (navigation.selectedSection == .tools
                && navigation.selectedDestination == .visualTimer)
    }

    private func synchronizeVisualTimerRuntime() {
        visualTimerRuntimeCoordinator.synchronize(
            controller: visualTimerController,
            isSceneActive: scenePhase == .active,
            isTimerPresented: isVisualTimerPresented
        )
    }

    @ViewBuilder
    private var appShell: some View {
        if forcesCompactNavigation {
            AppShellView(
                navigation: $navigation,
                visualTimerController: visualTimerController,
                forcesCompactNavigation: true
            )
            .environment(\.horizontalSizeClass, .compact)
        } else {
            AppShellView(
                navigation: $navigation,
                visualTimerController: visualTimerController,
                forcesCompactNavigation: false
            )
        }
    }

    @ViewBuilder
    private var childFacingContent: some View {
        if launchOptions.startsInChildFacingFixture {
            ChildFacingFixtureView()
        } else {
            VisualTimerChildView(controller: visualTimerController)
        }
    }

    private var forcesCompactNavigation: Bool {
        launchOptions.forcesCompactNavigation || fixtureForcesCompactNavigation
    }
}

private struct VisualTimerTimelineDriver: View {
    let controller: VisualTimerController
    let onSynchronizeRuntime: () -> Void

    var body: some View {
        TimelineView(
            .periodic(
                from: .now,
                by: controller.isRunning ? 0.25 : 60
            )
        ) { timeline in
            Color.clear
                .frame(width: 0, height: 0)
                .onAppear {
                    refreshAndSynchronize()
                }
                .onChange(of: timeline.date) {
                    refreshAndSynchronize()
                }
                .onChange(of: controller.phase) {
                    onSynchronizeRuntime()
                }
                .onChange(of: controller.completionSequence) {
                    onSynchronizeRuntime()
                }
        }
        .accessibilityHidden(true)
    }

    private func refreshAndSynchronize() {
        controller.refresh()
        onSynchronizeRuntime()
    }
}

private struct VisualTimerBanner: View {
    @Environment(\.otAccessibilityPreferences) private var accessibilityPreferences

    let controller: VisualTimerController
    let isTimerPresented: Bool
    let onOpenTimer: () -> Void

    var body: some View {
        if controller.phase != .idle, !isTimerPresented {
            Button(action: onOpenTimer) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: OTSpacing.md) {
                        bannerSymbol
                        statusLabel
                        Spacer(minLength: OTSpacing.sm)
                        remainingTime
                        openIndicator
                    }

                    HStack(alignment: .top, spacing: OTSpacing.md) {
                        bannerSymbol
                        VStack(alignment: .leading, spacing: OTSpacing.xs) {
                            statusLabel
                            remainingTime
                        }
                        Spacer(minLength: 0)
                        openIndicator
                    }
                }
                .padding(.horizontal, OTSpacing.md)
                .padding(.vertical, OTSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(OTColor.elevatedSurface)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(OTColor.separator)
                        .frame(height: accessibilityPreferences.boundaryLineWidth)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .otMinimumInteractiveSize()
            .accessibilityLabel("visualTimer.banner.open")
            .accessibilityValue(
                Text(statusKey)
                    + Text(verbatim: ", \(controller.remainingAccessibilityValue)")
            )
            .accessibilityIdentifier("visualTimer.banner")
        }
    }

    private var bannerSymbol: some View {
        Image(systemName: statusSymbol)
            .font(OTTypography.sectionHeading)
            .foregroundStyle(OTColor.accent)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityHidden(true)
    }

    private var statusLabel: some View {
        Text(statusKey)
            .font(OTTypography.controlLabel)
            .foregroundStyle(OTColor.primaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var remainingTime: some View {
        Text(controller.remainingClockText)
            .font(OTTypography.sectionHeading)
            .monospacedDigit()
            .foregroundStyle(OTColor.primaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    private var openIndicator: some View {
        Image(systemName: "chevron.up")
            .font(OTTypography.controlLabel)
            .foregroundStyle(OTColor.secondaryText)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityHidden(true)
    }

    private var statusKey: LocalizedStringKey {
        switch controller.phase {
        case .idle:
            "visualTimer.status.ready"
        case .running:
            "visualTimer.status.running"
        case .paused:
            "visualTimer.status.paused"
        case .completed:
            "visualTimer.status.completed"
        }
    }

    private var statusSymbol: String {
        switch controller.phase {
        case .idle:
            "timer"
        case .running:
            "timer"
        case .paused:
            "pause.circle.fill"
        case .completed:
            "checkmark.circle.fill"
        }
    }
}

struct AppShellView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var navigation: AppNavigationState

    let visualTimerController: VisualTimerController
    let forcesCompactNavigation: Bool

    var body: some View {
        switch navigationLayout {
        case .compactTabs:
            compactNavigation
        case .regularSplit:
            regularNavigation
        }
    }

    private var compactNavigation: some View {
        TabView(selection: selectedSectionBinding) {
            NavigationStack(path: compactToolsPathBinding) {
                HomeView {
                    navigation.show(.visualTimer)
                }
                .navigationDestination(for: AppDestination.self) { destination in
                    destinationView(for: destination)
                }
            }
            .tabItem {
                Label(AppSection.tools.titleKey, systemImage: AppSection.tools.symbolName)
            }
            .accessibilityIdentifier(AppSection.tools.tabIdentifier)
            .tag(AppSection.tools)

            NavigationStack {
                sectionPlaceholder(for: .saved)
            }
            .tabItem {
                Label(AppSection.saved.titleKey, systemImage: AppSection.saved.symbolName)
            }
            .accessibilityIdentifier(AppSection.saved.tabIdentifier)
            .tag(AppSection.saved)

            NavigationStack {
                sectionPlaceholder(for: .settings)
            }
            .tabItem {
                Label(AppSection.settings.titleKey, systemImage: AppSection.settings.symbolName)
            }
            .accessibilityIdentifier(AppSection.settings.tabIdentifier)
            .tag(AppSection.settings)
        }
        .accessibilityIdentifier("navigation.compact")
    }

    private var regularNavigation: some View {
        NavigationSplitView {
            List(selection: splitSectionSelectionBinding) {
                ForEach(AppSection.allCases) { section in
                    Label {
                        Text(section.titleKey)
                    } icon: {
                        Image(systemName: section.symbolName)
                            .accessibilityHidden(true)
                    }
                    .accessibilityElement(children: .combine)
                    .tag(section)
                    .accessibilityIdentifier(section.sidebarIdentifier)
                }
            }
            .navigationTitle("app.title")
        } content: {
            sectionContent
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .accessibilityIdentifier("navigation.regular")
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch navigation.selectedSection {
        case .tools:
            HomeView {
                navigation.show(.visualTimer)
            }
        case .saved:
            sectionPlaceholder(for: .saved)
        case .settings:
            sectionPlaceholder(for: .settings)
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        if navigation.selectedSection == .tools {
            if let destination = navigation.selectedDestination {
                destinationView(for: destination)
            } else {
                VStack(spacing: OTSpacing.sm) {
                    Image(systemName: "timer")
                        .font(OTTypography.screenTitle)
                        .foregroundStyle(OTColor.accent)
                        .accessibilityHidden(true)

                    Text("navigation.detail.prompt")
                        .font(OTTypography.sectionHeading)
                        .foregroundStyle(OTColor.primaryText)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text("navigation.detail.prompt.detail")
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(OTSpacing.xl)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(OTColor.background)
                .accessibilityIdentifier("navigation.detail.empty")
            }
        } else {
            OTColor.background
                .ignoresSafeArea()
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .visualTimer:
            VisualTimerView(
                controller: visualTimerController,
                onPresentChildFacing: {
                    navigation.presentChildFacing(.visualTimer)
                }
            )
        }
    }

    private func sectionPlaceholder(for section: AppSection) -> some View {
        AppSectionPlaceholderView(section: section)
    }

    private var navigationLayout: AppNavigationLayout {
        AppNavigationLayoutResolver.resolve(
            deviceFamily: deviceFamily,
            horizontalSize: appHorizontalSize,
            forcesCompactNavigation: forcesCompactNavigation
        )
    }

    private var deviceFamily: AppDeviceFamily {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            .phone
        case .pad:
            .pad
        default:
            .other
        }
    }

    private var appHorizontalSize: AppHorizontalSize {
        switch horizontalSizeClass {
        case .compact:
            .compact
        case .regular:
            .regular
        case nil:
            .unspecified
        @unknown default:
            .unspecified
        }
    }

    private var selectedSectionBinding: Binding<AppSection> {
        Binding(
            get: { navigation.selectedSection },
            set: { navigation.select(section: $0) }
        )
    }

    private var splitSectionSelectionBinding: Binding<AppSection?> {
        Binding(
            get: { navigation.selectedSection },
            set: { section in
                if let section {
                    navigation.select(section: section)
                }
            }
        )
    }

    private var compactToolsPathBinding: Binding<[AppDestination]> {
        Binding(
            get: { navigation.compactToolsPath },
            set: { navigation.compactToolsPath = $0 }
        )
    }
}

private struct AppSectionPlaceholderView: View {
    let section: AppSection

    var body: some View {
        ScrollView {
            Text(section.placeholderDetailKey)
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(OTSpacing.xl)
        }
        .background(OTColor.background.ignoresSafeArea())
        .navigationTitle(section.titleKey)
        .accessibilityIdentifier(section.contentIdentifier)
    }
}

private struct ChildFacingFixtureView: View {
    var body: some View {
        VStack(spacing: OTSpacing.md) {
            Image(systemName: "timer")
                .font(OTTypography.childFacingValue)
                .foregroundStyle(OTColor.accent)
                .accessibilityHidden(true)

            Text("child.fixture.title")
                .font(OTTypography.childFacingValue)
                .foregroundStyle(OTColor.primaryText)
                .multilineTextAlignment(.center)

            Text("child.fixture.detail")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("child.fixture")
    }
}

private extension AppSection {
    var titleKey: LocalizedStringKey {
        switch self {
        case .tools:
            "navigation.tools"
        case .saved:
            "navigation.saved"
        case .settings:
            "navigation.settings"
        }
    }

    var placeholderDetailKey: LocalizedStringKey {
        switch self {
        case .tools:
            "home.subtitle"
        case .saved:
            "navigation.saved.placeholder"
        case .settings:
            "navigation.settings.placeholder"
        }
    }

    var symbolName: String {
        switch self {
        case .tools:
            "square.grid.2x2"
        case .saved:
            "folder"
        case .settings:
            "gearshape"
        }
    }

    var tabIdentifier: String {
        "navigation.tab.\(identifierComponent)"
    }

    var sidebarIdentifier: String {
        "navigation.sidebar.\(identifierComponent)"
    }

    var contentIdentifier: String {
        "navigation.content.\(identifierComponent)"
    }

    private var identifierComponent: String {
        switch self {
        case .tools:
            "tools"
        case .saved:
            "saved"
        case .settings:
            "settings"
        }
    }
}
