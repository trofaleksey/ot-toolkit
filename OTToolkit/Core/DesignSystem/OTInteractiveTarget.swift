import SwiftUI

enum OTControlMetrics {
    static let minimumInteractiveDimension: CGFloat = 44
}

private struct OTMinimumInteractiveSizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(
                minWidth: OTControlMetrics.minimumInteractiveDimension,
                minHeight: OTControlMetrics.minimumInteractiveDimension
            )
            .contentShape(Rectangle())
    }
}

extension View {
    func otMinimumInteractiveSize() -> some View {
        modifier(OTMinimumInteractiveSizeModifier())
    }
}
