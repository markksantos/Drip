import SwiftUI
import Drip

// MARK: - Popover View

public struct PopoverView: View {
    @ObservedObject var viewModel: DripViewModel

    public init(viewModel: DripViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            connectionHeader
            Divider()
            usageSection
            Divider()
            sessionStatsSection
            Divider()
            quickActionsRow
        }
        .padding(16)
        .frame(width: 300)
    }

    // MARK: - Connection Header

    private var connectionHeader: some View {
        HStack {
            Image(systemName: "wifi")
                .foregroundStyle(.green)
            Text("Connected to \(viewModel.connectedHotspotName ?? "Unknown")")
                .font(.headline)
                .lineLimit(1)
            Spacer()
        }
    }

    // MARK: - Usage Section

    private var usageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Data Usage")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.formattedUsage)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }

            if let profile = viewModel.activeProfile, profile.dataLimitBytes != nil {
                UsageProgressBar(ratio: viewModel.usageRatio)
            } else {
                // Unlimited plan — show total usage without bar
                Text("Unlimited plan")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Download / Upload split
            if let session = viewModel.currentSession {
                HStack {
                    Label(ByteFormatter.string(from: session.bytesDown), systemImage: "arrow.down.circle.fill")
                        .foregroundStyle(.blue)
                    Spacer()
                    Label(ByteFormatter.string(from: session.bytesUp), systemImage: "arrow.up.circle.fill")
                        .foregroundStyle(.orange)
                }
                .font(.caption)
                .monospacedDigit()
            }
        }
    }

    // MARK: - Session Stats

    private var sessionStatsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Current Session")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Label(viewModel.formattedSessionDuration, systemImage: "clock")
                Spacer()
                if let session = viewModel.currentSession {
                    let sessionTotal = session.bytesDown + session.bytesUp
                    Label(ByteFormatter.string(from: sessionTotal), systemImage: "arrow.up.arrow.down")
                }
            }
            .font(.caption)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack {
            Button {
                viewModel.resetUsage()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .controlSize(.small)

            Spacer()

            if viewModel.profiles.count > 1 {
                Menu {
                    ForEach(viewModel.profiles) { profile in
                        Button(profile.name) {
                            viewModel.switchProfile(profile)
                        }
                    }
                } label: {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .controlSize(.small)
            }

            Spacer()

            Button {
                openSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .controlSize(.small)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .controlSize(.small)
        }
    }

    private func openSettings() {
        SettingsWindowController.shared.open(viewModel: viewModel)
    }
}

// MARK: - Usage Progress Bar

public struct UsageProgressBar: View {
    let ratio: Double

    private var barColor: Color {
        switch UsageLevel.from(ratio: ratio) {
        case .normal: return .blue
        case .warning: return .yellow
        case .critical: return .red
        }
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(width: max(geometry.size.width * CGFloat(ratio), 0), height: 8)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Preview

#if DEBUG
struct PopoverView_Previews: PreviewProvider {
    static var previews: some View {
        PopoverView(viewModel: .mock())
    }
}
#endif
