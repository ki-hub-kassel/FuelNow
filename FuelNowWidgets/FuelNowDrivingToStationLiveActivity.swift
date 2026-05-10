import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - DrivingToStationLiveActivity (Roadmap Phase 5)

struct DrivingToStationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DrivingToStationActivityAttributes.self) { context in
            DrivingToStationLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "fuelpump.fill")
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.distanceText)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.brandTitle)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("\(context.attributes.fuelDisplayName) · \(context.attributes.pumpPriceText)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let eta = context.state.etaText {
                        Text(eta)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            } compactLeading: {
                Image(systemName: "fuelpump.fill")
                    .foregroundStyle(.white)
            } compactTrailing: {
                Text(context.state.distanceText)
                    .font(.headline)
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: "fuelpump.fill")
                    .foregroundStyle(.white)
            }
            .keylineTint(.green)
        }
    }
}

private struct DrivingToStationLockScreenView: View {
    let context: ActivityViewContext<DrivingToStationActivityAttributes>

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "fuelpump.fill")
                .font(.title2)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.brandTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(context.attributes.fuelDisplayName) · \(context.attributes.pumpPriceText)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(context.state.distanceText)
                    .font(.headline)
                    .foregroundStyle(.white)
                if let eta = context.state.etaText {
                    Text(eta)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fahrt zu \(context.attributes.stationName), \(context.state.distanceText)")
    }
}
