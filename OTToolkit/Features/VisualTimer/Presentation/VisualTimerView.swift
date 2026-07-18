import SwiftUI

struct VisualTimerView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var isConfirmingReset = false

    let controller: VisualTimerController
    let onPresentChildFacing: () -> Void

    var body: some View {
        ScrollView {
            Group {
                if controller.phase == .idle {
                    setupContent
                } else {
                    activeContent
                }
            }
            .frame(maxWidth: 720)
            .padding(.horizontal, horizontalContentPadding)
            .padding(.vertical, OTSpacing.xl)
            .frame(maxWidth: .infinity)
        }
        .background(OTColor.background.ignoresSafeArea())
        .navigationTitle("tool.visualTimer.title")
        .accessibilityIdentifier("tool.visualTimer.destination")
        .alert("visualTimer.reset.title", isPresented: $isConfirmingReset) {
            Button("visualTimer.reset.stay", role: .cancel) {}
            Button("visualTimer.reset.confirm", role: .destructive) {
                controller.reset()
            }
        } message: {
            Text("visualTimer.reset.message")
        }
    }

    private var setupContent: some View {
        VStack(alignment: .leading, spacing: OTSpacing.lg) {
            VStack(alignment: .leading, spacing: OTSpacing.xs) {
                Text("visualTimer.setup.duration")
                    .font(OTTypography.screenTitle)
                    .foregroundStyle(OTColor.primaryText)
                    .accessibilityAddTraits(.isHeader)

                Text("visualTimer.setup.maximum")
                    .font(OTTypography.body)
                    .foregroundStyle(OTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: OTSpacing.sm) {
                Text("visualTimer.setup.presets")
                    .font(OTTypography.sectionHeading)
                    .foregroundStyle(OTColor.primaryText)
                    .accessibilityAddTraits(.isHeader)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 96), spacing: OTSpacing.sm)],
                    spacing: OTSpacing.sm
                ) {
                    ForEach(VisualTimerPreset.allCases) { preset in
                        presetButton(preset)
                    }
                }
            }

            customDurationControl

            Button {
                controller.start()
            } label: {
                Label("visualTimer.action.start", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .font(OTTypography.controlLabel)
            }
            .buttonStyle(.borderedProminent)
            .tint(OTColor.accent)
            .controlSize(.large)
            .otMinimumInteractiveSize()
            .accessibilityValue(controller.selectedDurationDescription)
            .accessibilityIdentifier("visualTimer.action.start")
            .keyboardShortcut(.defaultAction)

            completionFeedbackSettings

            lifecycleLimitDisclosure
        }
    }

    private var completionFeedbackSettings: some View {
        VStack(alignment: .leading, spacing: OTSpacing.sm) {
            Text("visualTimer.feedback.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            Text("visualTimer.feedback.description")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            feedbackToggle(
                "visualTimer.feedback.sound",
                isOn: Binding(
                    get: { controller.isCompletionSoundEnabled },
                    set: { controller.setCompletionSoundEnabled($0) }
                ),
                identifier: "visualTimer.feedback.sound"
            )

            feedbackToggle(
                "visualTimer.feedback.haptic",
                isOn: Binding(
                    get: { controller.isCompletionHapticEnabled },
                    set: { controller.setCompletionHapticEnabled($0) }
                ),
                identifier: "visualTimer.feedback.haptic"
            )
        }
        .padding(OTSpacing.md)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                .stroke(OTColor.separator, lineWidth: 1)
        }
    }

    private var horizontalContentPadding: CGFloat {
        horizontalSizeClass == .compact ? OTSpacing.md : OTSpacing.xl
    }

    private func feedbackToggle(
        _ titleKey: LocalizedStringKey,
        isOn: Binding<Bool>,
        identifier: String
    ) -> some View {
        Toggle(isOn: isOn) {
            Text(titleKey)
                .font(OTTypography.controlLabel)
                .foregroundStyle(OTColor.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .tint(OTColor.accent)
        .otMinimumInteractiveSize()
        .accessibilityIdentifier(identifier)
    }

    private var lifecycleLimitDisclosure: some View {
        HStack(alignment: .top, spacing: OTSpacing.sm) {
            Image(systemName: "info.circle")
                .foregroundStyle(OTColor.accent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: OTSpacing.xs) {
                Text("visualTimer.lifecycle.title")
                    .font(OTTypography.sectionHeading)
                    .foregroundStyle(OTColor.primaryText)
                    .accessibilityAddTraits(.isHeader)

                Text("visualTimer.lifecycle.processLoss")
                    .font(OTTypography.body)
                    .foregroundStyle(OTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("visualTimer.lifecycle.disclosure")

                Text("visualTimer.lifecycle.noAlerts")
                    .font(OTTypography.body)
                    .foregroundStyle(OTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("visualTimer.lifecycle.alertsDisclosure")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(OTSpacing.md)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                .stroke(OTColor.separator, lineWidth: 1)
        }
    }

    private var customDurationControl: some View {
        VStack(alignment: .leading, spacing: OTSpacing.sm) {
            Button {
                controller.selectCurrentCustomDuration()
            } label: {
                HStack(spacing: OTSpacing.sm) {
                    Image(
                        systemName: controller.selectedPreset == nil
                            ? "checkmark.circle.fill" : "circle"
                    )
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: OTSpacing.xs) {
                        Text("visualTimer.setup.custom")
                            .font(OTTypography.sectionHeading)
                        Text(controller.customDurationDescription)
                            .font(OTTypography.body)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .foregroundStyle(OTColor.primaryText)
            .otMinimumInteractiveSize()
            .accessibilityAddTraits(controller.selectedPreset == nil ? .isSelected : [])
            .accessibilityIdentifier("visualTimer.duration.custom.select")

            Stepper(
                value: Binding(
                    get: { controller.customMinutes },
                    set: { controller.selectCustom(minutes: $0) }
                ),
                in: VisualTimerController.customMinuteRange
            ) {
                Text("visualTimer.setup.custom.adjust")
                    .font(OTTypography.controlLabel)
                    .foregroundStyle(OTColor.secondaryText)
            }
            .otMinimumInteractiveSize()
            .accessibilityValue(controller.customDurationDescription)
            .accessibilityIdentifier("visualTimer.duration.custom.stepper")
        }
        .padding(OTSpacing.md)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                .stroke(
                    controller.selectedPreset == nil ? OTColor.accent : OTColor.separator,
                    lineWidth: 1
                )
        }
    }

    @ViewBuilder
    private var activeContent: some View {
        if verticalSizeClass == .compact {
            HStack(spacing: OTSpacing.lg) {
                VisualTimerStatusView(controller: controller)
                    .frame(maxWidth: .infinity)

                activeControls
                    .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: OTSpacing.lg) {
                VisualTimerStatusView(controller: controller)

                activeControls
            }
        }
    }

    private var activeControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: OTSpacing.sm) {
                primaryStateButton
                resetButton
                childFacingButton
            }

            VStack(spacing: OTSpacing.sm) {
                primaryStateButton
                resetButton
                childFacingButton
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var primaryStateButton: some View {
        switch controller.phase {
        case .running:
            Button {
                controller.pause()
            } label: {
                Label("visualTimer.action.pause", systemImage: "pause.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(OTColor.accent)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("visualTimer.action.pause")
            .keyboardShortcut(.space, modifiers: [])
        case .paused:
            Button {
                controller.resume()
            } label: {
                Label("visualTimer.action.resume", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(OTColor.accent)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("visualTimer.action.resume")
            .keyboardShortcut(.space, modifiers: [])
        case .completed:
            Button {
                controller.reset()
            } label: {
                Label("visualTimer.action.another", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(OTColor.accent)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("visualTimer.action.another")
            .keyboardShortcut(.defaultAction)
        case .idle:
            EmptyView()
        }
    }

    @ViewBuilder
    private var resetButton: some View {
        if controller.phase == .running || controller.phase == .paused {
            Button(role: .destructive) {
                isConfirmingReset = true
            } label: {
                Label("visualTimer.action.reset", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("visualTimer.action.reset")
        }
    }

    private var childFacingButton: some View {
        Button(action: onPresentChildFacing) {
            Label("visualTimer.action.childFacing", systemImage: "rectangle.inset.filled")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(OTColor.accent)
        .otMinimumInteractiveSize()
        .accessibilityIdentifier("visualTimer.action.childFacing")
    }

    private func presetButton(_ preset: VisualTimerPreset) -> some View {
        let isSelected = controller.selectedPreset == preset

        return Button {
            controller.select(preset)
        } label: {
            VStack(spacing: OTSpacing.xs) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .accessibilityHidden(true)
                Text(preset.titleKey)
                    .font(OTTypography.controlLabel)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(OTColor.accent)
        .otMinimumInteractiveSize()
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("visualTimer.duration.preset.\(preset.rawValue)")
    }
}

struct VisualTimerChildView: View {
    let controller: VisualTimerController

    var body: some View {
        VisualTimerStatusView(controller: controller)
            .frame(maxWidth: 720)
            .accessibilityIdentifier("visualTimer.child.content")
    }
}

private struct VisualTimerStatusView: View {
    @Environment(\.otAccessibilityPreferences) private var accessibilityPreferences
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let controller: VisualTimerController

    var body: some View {
        VStack(spacing: verticalSizeClass == .compact ? OTSpacing.sm : OTSpacing.lg) {
            Label(statusKey, systemImage: statusSymbol)
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(statusIdentifier)

            VisualTimerSpatialProgress(
                fraction: controller.progressFraction,
                usesDiscreteSegments: !accessibilityPreferences.allowsNonessentialMotion,
                boundaryLineWidth: accessibilityPreferences.boundaryLineWidth
            )
            .frame(maxWidth: 220)
            .frame(height: verticalSizeClass == .compact ? 120 : 240)
            .accessibilityHidden(true)

            Text(controller.remainingClockText)
                .font(OTTypography.childFacingValue)
                .monospacedDigit()
                .foregroundStyle(OTColor.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityLabel("visualTimer.accessibility.remaining")
                .accessibilityValue(controller.remainingAccessibilityValue)
                .accessibilityIdentifier("visualTimer.remaining")
        }
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
            "play.circle.fill"
        case .paused:
            "pause.circle.fill"
        case .completed:
            "checkmark.circle.fill"
        }
    }

    private var statusIdentifier: String {
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
}

private struct VisualTimerSpatialProgress: View {
    let fraction: Double
    let usesDiscreteSegments: Bool
    let boundaryLineWidth: CGFloat

    var body: some View {
        if usesDiscreteSegments {
            discreteProgress
        } else {
            continuousProgress
        }
    }

    private var continuousProgress: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                    .fill(OTColor.surface)

                RoundedRectangle(cornerRadius: OTRadius.control, style: .continuous)
                    .fill(OTColor.accent)
                    .frame(
                        height: max(
                            0,
                            (geometry.size.height - OTSpacing.md) * fraction
                        )
                    )
                    .padding(OTSpacing.sm)
            }
            .overlay {
                RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                    .stroke(OTColor.separator, lineWidth: boundaryLineWidth)
            }
        }
    }

    private var discreteProgress: some View {
        let filledSegments = Int(ceil(fraction * 10))

        return VStack(spacing: OTSpacing.xs) {
            ForEach((0..<10).reversed(), id: \.self) { segment in
                RoundedRectangle(cornerRadius: OTRadius.control, style: .continuous)
                    .fill(segment < filledSegments ? OTColor.accent : OTColor.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: OTRadius.control, style: .continuous)
                            .stroke(OTColor.separator, lineWidth: boundaryLineWidth)
                    }
            }
        }
    }
}

private extension VisualTimerPreset {
    var titleKey: LocalizedStringKey {
        switch self {
        case .oneMinute:
            "visualTimer.preset.oneMinute"
        case .threeMinutes:
            "visualTimer.preset.threeMinutes"
        case .fiveMinutes:
            "visualTimer.preset.fiveMinutes"
        case .tenMinutes:
            "visualTimer.preset.tenMinutes"
        case .fifteenMinutes:
            "visualTimer.preset.fifteenMinutes"
        }
    }
}
