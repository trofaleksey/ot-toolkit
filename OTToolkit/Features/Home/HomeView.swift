import SwiftUI

struct HomeView: View {
    @Environment(\.otAccessibilityPreferences) private var accessibilityPreferences
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OTSpacing.lg) {
                VStack(alignment: .leading, spacing: OTSpacing.sm) {
                    Text("home.title")
                        .font(OTTypography.screenTitle)
                        .foregroundStyle(OTColor.primaryText)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("home.title")

                    Text("home.subtitle")
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                foundationStatus
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(OTSpacing.xl)
        }
        .background(OTColor.background.ignoresSafeArea())
        .transaction { transaction in
            if !accessibilityPreferences.allowsNonessentialMotion {
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        }
    }

    private var foundationStatus: some View {
        VStack(alignment: .leading, spacing: OTSpacing.sm) {
            foundationStatusHeader

            Text("home.foundation.detail")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            OTColor.surface,
            in: RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                .stroke(
                    OTColor.separator,
                    lineWidth: accessibilityPreferences.boundaryLineWidth
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home.foundation.status")
    }

    @ViewBuilder
    private var foundationStatusHeader: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: OTSpacing.sm) {
                foundationStatusIcon
                foundationStatusText
            }
        } else {
            Label {
                foundationStatusText
            } icon: {
                foundationStatusIcon
            }
        }
    }

    private var foundationStatusText: some View {
        Text("home.foundation.status")
            .font(OTTypography.sectionHeading)
            .foregroundStyle(OTColor.primaryText)
    }

    private var foundationStatusIcon: some View {
        Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(OTColor.success)
            .accessibilityHidden(true)
    }
}
