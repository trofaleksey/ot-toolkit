import SwiftUI

struct HomeView: View {
    @Environment(\.otAccessibilityPreferences) private var accessibilityPreferences

    let onOpenVisualTimer: () -> Void
    let onOpenFirstThenBoards: () -> Void
    let onOpenTokenBoards: () -> Void

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

                visualTimerCard
                firstThenCard
                tokenBoardCard
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

    private var visualTimerCard: some View {
        Button {
            onOpenVisualTimer()
        } label: {
            HStack(alignment: .top, spacing: OTSpacing.md) {
                Image(systemName: "timer")
                    .font(OTTypography.sectionHeading)
                    .foregroundStyle(OTColor.accent)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: OTSpacing.xs) {
                    Text("tool.visualTimer.title")
                        .font(OTTypography.sectionHeading)
                        .foregroundStyle(OTColor.primaryText)

                    Text("tool.visualTimer.summary")
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
        }
        .buttonStyle(.plain)
        .otMinimumInteractiveSize()
        .accessibilityIdentifier("home.tool.visualTimer")
    }

    private var tokenBoardCard: some View {
        Button {
            onOpenTokenBoards()
        } label: {
            HStack(alignment: .top, spacing: OTSpacing.md) {
                Image(systemName: "circle.grid.2x2")
                    .font(OTTypography.sectionHeading)
                    .foregroundStyle(OTColor.accent)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: OTSpacing.xs) {
                    Text("tokenBoard.title")
                        .font(OTTypography.sectionHeading)
                        .foregroundStyle(OTColor.primaryText)

                    Text("tokenBoard.summary")
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
        }
        .buttonStyle(.plain)
        .otMinimumInteractiveSize()
        .accessibilityIdentifier("home.tool.tokenBoard")
    }

    private var firstThenCard: some View {
        Button {
            onOpenFirstThenBoards()
        } label: {
            HStack(alignment: .top, spacing: OTSpacing.md) {
                Image(systemName: "rectangle.split.2x1")
                    .font(OTTypography.sectionHeading)
                    .foregroundStyle(OTColor.accent)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: OTSpacing.xs) {
                    Text("firstThen.title")
                        .font(OTTypography.sectionHeading)
                        .foregroundStyle(OTColor.primaryText)

                    Text("firstThen.summary")
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
        }
        .buttonStyle(.plain)
        .otMinimumInteractiveSize()
        .accessibilityIdentifier("home.tool.firstThen")
    }
}
