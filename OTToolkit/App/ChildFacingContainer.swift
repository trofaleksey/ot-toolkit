import SwiftUI

struct ChildFacingContainer<Content: View>: View {
    @State private var isConfirmingExit = false

    let onExit: () -> Void
    private let content: Content

    init(onExit: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onExit = onExit
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: .infinity)
                .padding(OTSpacing.xl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            OTAdultExitControl {
                isConfirmingExit = true
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, OTSpacing.md)
            .padding(.vertical, OTSpacing.sm)
            .background(OTColor.background)
        }
        .background(OTColor.background.ignoresSafeArea())
        .alert("child.exit.confirmation.title", isPresented: $isConfirmingExit) {
            Button("child.exit.confirmation.stay", role: .cancel) {}
            Button("child.exit.confirmation.return") {
                onExit()
            }
        } message: {
            Text("child.exit.confirmation.message")
        }
    }
}
