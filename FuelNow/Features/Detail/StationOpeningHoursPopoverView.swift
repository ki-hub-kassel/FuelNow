import SwiftUI

/// Öffnungszeiten-Popover für die Tankstellen-Detailansicht.
struct StationOpeningHoursPopoverView: View {
    var phase: StationDetailFetchPhase
    var enrichedStation: Station?
    var listStation: Station

    private var displayStation: Station {
        enrichedStation ?? listStation
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.m) {
            Text(String(localized: "station.openingHours.title"))
                .font(TRTypography.title2())
                .fixedSize(horizontal: false, vertical: true)

            switch phase {
            case .loading:
                ProgressView()
                Text(String(localized: "station.openingHours.loading"))
                    .font(TRTypography.subheadline())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            case .failed:
                Text(String(localized: "station.openingHours.loadFailed"))
                    .font(TRTypography.subheadline())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            case .idle, .loaded:
                loadedBody
            }
        }
        .padding(TRSpacing.m)
        .frame(minWidth: 288, maxWidth: 340, alignment: .leading)
    }

    @ViewBuilder
    private var loadedBody: some View {
        let model = StationOpeningHoursPresenter.popoverModel(station: displayStation)

        if let primary = model.primaryLine {
            Text(primary)
                .font(TRTypography.bodyBold())
                .foregroundStyle(TRColors.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }

        if model.scheduleLines.isEmpty {
            Text(String(localized: "station.openingHours.noSchedule"))
                .font(TRTypography.subheadline())
                .foregroundStyle(TRColors.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(String(localized: "station.openingHours.section.schedule"))
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelSecondary)
                .textCase(.uppercase)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: TRSpacing.xs) {
                ForEach(Array(model.scheduleLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(TRTypography.subheadline())
                        .foregroundStyle(TRColors.labelPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }

        if let overrides = model.overrideLines, !overrides.isEmpty {
            Text(String(localized: "station.openingHours.section.overrides"))
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelSecondary)
                .textCase(.uppercase)
                .padding(.top, TRSpacing.xs)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: TRSpacing.xs) {
                ForEach(Array(overrides.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(TRTypography.caption())
                        .foregroundStyle(TRColors.labelPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }

        Text(String(localized: "station.openingHours.footer.source"))
            .font(TRTypography.captionSmall())
            .foregroundStyle(TRColors.labelTertiary)
            .padding(.top, TRSpacing.s)
            .fixedSize(horizontal: false, vertical: true)
    }
}
