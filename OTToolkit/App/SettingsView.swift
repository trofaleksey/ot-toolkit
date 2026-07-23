import SwiftUI

enum AppResetOutcome: Equatable, Sendable {
    case succeeded
    case failed
}

/// Settings for preferences and disclosures the shipped behavior requires.
/// Deliberately not a general settings framework: no themes, typography, or
/// board appearance controls.
struct SettingsView: View {
    @State private var isConfirmingReset = false
    @State private var resetOutcome: AppResetOutcome?

    let dataController: AppDataController
    let visualTimerController: VisualTimerController
    let tokenBoardSessionController: TokenBoardSessionController

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OTSpacing.lg) {
                feedbackSection
                disclosureSection
                resetSection
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(OTSpacing.xl)
            .frame(maxWidth: .infinity)
        }
        .background(OTColor.background.ignoresSafeArea())
        .navigationTitle("navigation.settings")
        .accessibilityIdentifier("navigation.content.settings")
        .alert("settings.reset.title", isPresented: $isConfirmingReset) {
            Button("settings.reset.cancel", role: .cancel) {}
            Button("settings.reset.confirm", role: .destructive) {
                resetOutcome = dataController.reset() ? .succeeded : .failed
            }
        } message: {
            Text("settings.reset.message")
        }
        .alert(
            resetOutcome == .succeeded
                ? "settings.reset.success.title" : "settings.reset.failure.title",
            isPresented: resetOutcomeBinding
        ) {
            Button("settings.reset.dismiss", role: .cancel) {
                resetOutcome = nil
            }
        } message: {
            Text(
                resetOutcome == .succeeded
                    ? "settings.reset.success.message" : "settings.reset.failure.message"
            )
        }
    }

    private var feedbackSection: some View {
        section(
            titleKey: "settings.feedback.title",
            messageKey: "settings.feedback.message",
            identifier: "settings.feedback"
        ) {
            toggle(
                "settings.feedback.timer.sound",
                isOn: Binding(
                    get: { visualTimerController.isCompletionSoundEnabled },
                    set: { visualTimerController.setCompletionSoundEnabled($0) }
                ),
                identifier: "settings.feedback.timer.sound"
            )
            toggle(
                "settings.feedback.timer.haptic",
                isOn: Binding(
                    get: { visualTimerController.isCompletionHapticEnabled },
                    set: { visualTimerController.setCompletionHapticEnabled($0) }
                ),
                identifier: "settings.feedback.timer.haptic"
            )
            toggle(
                "settings.feedback.tokenBoard.haptic",
                isOn: Binding(
                    get: { tokenBoardSessionController.isCompletionHapticEnabled },
                    set: { tokenBoardSessionController.setCompletionHapticEnabled($0) }
                ),
                identifier: "settings.feedback.tokenBoard.haptic"
            )
        }
    }

    private var disclosureSection: some View {
        section(
            titleKey: "settings.disclosure.title",
            messageKey: nil,
            identifier: "settings.disclosure"
        ) {
            disclosure(
                titleKey: "settings.disclosure.timer.title",
                messageKey: "settings.disclosure.timer.message",
                symbolName: "timer",
                identifier: "settings.disclosure.timer"
            )
            disclosure(
                titleKey: "settings.disclosure.backup.title",
                messageKey: "settings.disclosure.backup.message",
                symbolName: "externaldrive.badge.xmark",
                identifier: "settings.disclosure.backup"
            )
            disclosure(
                titleKey: "settings.disclosure.naming.title",
                messageKey: "settings.disclosure.naming.message",
                symbolName: "textformat",
                identifier: "settings.disclosure.naming"
            )
        }
    }

    private var resetSection: some View {
        section(
            titleKey: "settings.reset.section.title",
            messageKey: "settings.reset.section.message",
            identifier: "settings.reset"
        ) {
            Button("settings.reset.action", role: .destructive) {
                isConfirmingReset = true
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("settings.reset.action")
        }
    }

    private var resetOutcomeBinding: Binding<Bool> {
        Binding(
            get: { resetOutcome != nil },
            set: { isPresented in
                if !isPresented {
                    resetOutcome = nil
                }
            }
        )
    }

    private func toggle(
        _ titleKey: LocalizedStringKey,
        isOn: Binding<Bool>,
        identifier: String
    ) -> some View {
        Toggle(isOn: isOn) {
            Text(titleKey)
                .font(OTTypography.controlLabel)
                .foregroundStyle(OTColor.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .otMinimumInteractiveSize()
        .accessibilityIdentifier(identifier)
    }

    private func disclosure(
        titleKey: LocalizedStringKey,
        messageKey: LocalizedStringKey,
        symbolName: String,
        identifier: String
    ) -> some View {
        HStack(alignment: .top, spacing: OTSpacing.md) {
            Image(systemName: symbolName)
                .font(OTTypography.controlLabel)
                .foregroundStyle(OTColor.accent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: OTSpacing.xs) {
                Text(titleKey)
                    .font(OTTypography.controlLabel)
                    .foregroundStyle(OTColor.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(messageKey)
                    .font(OTTypography.body)
                    .foregroundStyle(OTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }

    private func section<Content: View>(
        titleKey: LocalizedStringKey,
        messageKey: LocalizedStringKey?,
        identifier: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: OTSpacing.md) {
            VStack(alignment: .leading, spacing: OTSpacing.xs) {
                Text(titleKey)
                    .font(OTTypography.sectionHeading)
                    .foregroundStyle(OTColor.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                if let messageKey {
                    Text(messageKey)
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content()
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                .stroke(OTColor.separator, lineWidth: 1)
                .accessibilityHidden(true)
        }
        // .contain keeps the section addressable without absorbing its children:
        // without it the toggles and disclosures collapse into one element and
        // stop being individually operable under VoiceOver.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }
}
