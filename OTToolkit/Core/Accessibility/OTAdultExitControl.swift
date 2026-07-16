import SwiftUI

struct OTAdultExitControl: View {
    @State private var isConfirmingExit = false

    let onConfirmExit: () -> Void

    var body: some View {
        Button {
            isConfirmingExit = true
        } label: {
            Label("child.exit.request", systemImage: "rectangle.portrait.and.arrow.right")
                .font(OTTypography.controlLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.bordered)
        .tint(OTColor.accent)
        .otMinimumInteractiveSize()
        .accessibilityHint("child.exit.hint")
        .accessibilityIdentifier("child.exit.request")
        .keyboardShortcut(.cancelAction)
        .alert("child.exit.confirmation.title", isPresented: $isConfirmingExit) {
            Button("child.exit.confirmation.stay", role: .cancel) {}
            Button("child.exit.confirmation.return") {
                onConfirmExit()
            }
        } message: {
            Text("child.exit.confirmation.message")
        }
    }
}
