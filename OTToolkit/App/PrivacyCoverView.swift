import SwiftUI

enum AppPrivacyCoverPolicy {
    static func isCoverRequired(isSceneActive: Bool, isForced: Bool) -> Bool {
        isForced || !isSceneActive
    }
}

struct PrivacyCoverView: View {
    var body: some View {
        VStack(spacing: OTSpacing.sm) {
            Text("privacy.cover.title")
                .font(OTTypography.screenTitle)
                .foregroundStyle(OTColor.primaryText)

            Text("privacy.cover.detail")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(OTSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OTColor.background)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("privacy.cover")
        .ignoresSafeArea()
    }
}
