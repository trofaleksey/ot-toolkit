import SwiftUI

struct PersistenceRecoveryView: View {
    @State private var isConfirmingReset = false

    let controller: AppDataController

    var body: some View {
        VStack(alignment: .leading, spacing: OTSpacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(OTTypography.screenTitle)
                .foregroundStyle(OTColor.warning)
                .accessibilityHidden(true)

            Text("persistence.recovery.title")
                .font(OTTypography.screenTitle)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            Text("persistence.recovery.message")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Button("persistence.recovery.retry") {
                controller.retry()
            }
            .buttonStyle(.borderedProminent)
            .tint(OTColor.accent)
            .controlSize(.large)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("persistence.recovery.retry")

            Button("persistence.recovery.reset", role: .destructive) {
                isConfirmingReset = true
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("persistence.recovery.reset")
        }
        .frame(maxWidth: 560, alignment: .leading)
        .padding(OTSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OTColor.background.ignoresSafeArea())
        .accessibilityIdentifier("persistence.recovery")
        .alert("persistence.recovery.reset.title", isPresented: $isConfirmingReset) {
            Button("persistence.recovery.reset.cancel", role: .cancel) {}
            Button("persistence.recovery.reset.confirm", role: .destructive) {
                controller.reset()
            }
        } message: {
            Text("persistence.recovery.reset.message")
        }
    }
}
