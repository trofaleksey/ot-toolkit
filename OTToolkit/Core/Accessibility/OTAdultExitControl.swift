import SwiftUI

struct OTAdultExitControl: View {
    let onRequestExit: () -> Void

    var body: some View {
        Button(action: onRequestExit) {
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
    }
}
