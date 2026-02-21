import SwiftUI
import Drip

// MARK: - Not Connected View

public struct NotConnectedView: View {
    @ObservedObject var viewModel: DripViewModel

    public init(viewModel: DripViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            disconnectedHeader
            Divider()
            recentHotspotsSection
            Divider()
            bottomActions
        }
        .padding(16)
        .frame(width: 300)
    }

    // MARK: - Disconnected Header

    private var disconnectedHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundStyle(.secondary)
                Text("No Hotspot Detected")
                    .font(.headline)
            }
            Text("Connect to a personal hotspot to start tracking data usage.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Recent Hotspots

    @ViewBuilder
    private var recentHotspotsSection: some View {
        let recents = viewModel.recentHotspots
        if recents.isEmpty {
            Text("No recent hotspots")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Recent Hotspots")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(recents.prefix(5), id: \.name) { hotspot in
                    HStack {
                        Image(systemName: "wifi")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(hotspot.name)
                            .font(.callout)
                        Spacer()
                        Text(hotspot.lastUsed, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        HStack {
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

// MARK: - Preview

#if DEBUG
struct NotConnectedView_Previews: PreviewProvider {
    static var previews: some View {
        NotConnectedView(viewModel: .mockDisconnected())
    }
}
#endif
