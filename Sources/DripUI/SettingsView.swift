import SwiftUI
import AppKit
import Drip

// MARK: - Settings View

public struct SettingsView: View {
    @ObservedObject var viewModel: DripViewModel

    public init(viewModel: DripViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        TabView {
            GeneralSettingsTab(viewModel: viewModel)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            ProfilesSettingsTab(viewModel: viewModel)
                .tabItem {
                    Label("Profiles", systemImage: "person.2")
                }

            HistorySettingsTab(viewModel: viewModel)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            AboutSettingsTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 360)
    }
}

// MARK: - General Tab

struct GeneralSettingsTab: View {
    @ObservedObject var viewModel: DripViewModel

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $viewModel.launchAtLogin)

            Toggle("Show Usage in Menu Bar", isOn: $viewModel.showUsageInMenuBar)

            Picker("Display Format", selection: $viewModel.displayFormat) {
                ForEach(DisplayFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Profiles Tab

struct ProfilesSettingsTab: View {
    @ObservedObject var viewModel: DripViewModel
    @State private var selectedProfileId: UUID?
    @State private var isEditing = false
    @State private var editingProfile: HotspotProfile?

    var body: some View {
        HSplitView {
            profileList
                .frame(minWidth: 160, maxWidth: 200)

            profileDetail
                .frame(minWidth: 260)
        }
        .padding()
    }

    private var profileList: some View {
        VStack(alignment: .leading, spacing: 0) {
            List(viewModel.profiles, selection: $selectedProfileId) { profile in
                Text(profile.name)
                    .tag(profile.id)
            }

            Divider()

            HStack(spacing: 4) {
                Button {
                    let newProfile = HotspotProfile(
                        name: "New Profile",
                        dataLimitBytes: DripConstants.defaultDataLimitBytes
                    )
                    viewModel.addProfile(newProfile)
                    selectedProfileId = newProfile.id
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)

                Button {
                    if let id = selectedProfileId,
                       let profile = viewModel.profiles.first(where: { $0.id == id }) {
                        viewModel.deleteProfile(profile)
                        selectedProfileId = viewModel.profiles.first?.id
                    }
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(.borderless)
                .disabled(selectedProfileId == nil || viewModel.profiles.count <= 1)

                Spacer()
            }
            .padding(6)
        }
    }

    @ViewBuilder
    private var profileDetail: some View {
        if let id = selectedProfileId,
           let profile = viewModel.profiles.first(where: { $0.id == id }) {
            ProfileEditView(profile: profile)
        } else {
            Text("Select a profile")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Profile Edit View

struct ProfileEditView: View {
    @ObservedObject var profile: HotspotProfile
    @State private var isUnlimited: Bool

    init(profile: HotspotProfile) {
        self.profile = profile
        self._isUnlimited = State(initialValue: profile.dataLimitBytes == nil)
    }

    private var limitGB: Binding<Double> {
        Binding(
            get: { Double(profile.dataLimitBytes ?? DripConstants.defaultDataLimitBytes) / 1_073_741_824 },
            set: { profile.dataLimitBytes = Int64($0 * 1_073_741_824) }
        )
    }

    var body: some View {
        Form {
            TextField("Name", text: $profile.name)

            Toggle("Unlimited Data", isOn: $isUnlimited)
                .onChange(of: isUnlimited) { newValue in
                    if newValue {
                        profile.dataLimitBytes = nil
                    } else {
                        profile.dataLimitBytes = DripConstants.defaultDataLimitBytes
                    }
                }

            if !isUnlimited {
                HStack {
                    Slider(value: limitGB, in: 1...100, step: 1)
                    Text("\(Int(limitGB.wrappedValue)) GB")
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }
            }

            Picker("Reset Cycle", selection: $profile.resetCycle) {
                ForEach(ResetCycle.allCases, id: \.self) { cycle in
                    Text(cycle.rawValue.capitalized).tag(cycle)
                }
            }

            if profile.resetCycle == .monthly {
                Stepper(
                    "Reset Day: \(profile.resetDay ?? 1)",
                    value: Binding(
                        get: { profile.resetDay ?? 1 },
                        set: { profile.resetDay = $0 }
                    ),
                    in: 1...28
                )
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - History Tab

struct HistorySettingsTab: View {
    @ObservedObject var viewModel: DripViewModel
    @State private var sortOrder = [KeyPathComparator(\UsageSession.startDate, order: .reverse)]

    var body: some View {
        VStack {
            Table(viewModel.sessionHistory, sortOrder: $sortOrder) {
                TableColumn("Hotspot", value: \.hotspotName)
                    .width(min: 80, ideal: 120)

                TableColumn("Date") { session in
                    Text(session.startDate, format: .dateTime.month().day().year())
                }
                .width(min: 80, ideal: 100)

                TableColumn("Duration") { session in
                    let duration = (session.endDate ?? Date()).timeIntervalSince(session.startDate)
                    let hours = Int(duration) / 3600
                    let minutes = (Int(duration) % 3600) / 60
                    Text(hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m")
                        .monospacedDigit()
                }
                .width(min: 60, ideal: 80)

                TableColumn("Data") { session in
                    Text(ByteFormatter.string(from: session.bytesDown + session.bytesUp))
                        .monospacedDigit()
                }
                .width(min: 60, ideal: 80)
            }
            .onChange(of: sortOrder) { newOrder in
                viewModel.sessionHistory.sort(using: newOrder)
            }

            HStack {
                Spacer()
                Button("Clear History", role: .destructive) {
                    viewModel.clearHistory()
                }
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - About Tab

struct AboutSettingsTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "drop.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Drip")
                .font(.title)
                .fontWeight(.bold)

            Text("Hotspot Data Usage Tracker")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Version \(DripUI.version)")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Settings Window Controller

/// Opens the settings window directly via NSWindow, bypassing the unreliable
/// Settings scene + sendAction approach that fails from MenuBarExtra popovers.
public final class SettingsWindowController {
    public static let shared = SettingsWindowController()

    private var window: NSWindow?

    private init() {}

    public func open(viewModel: DripViewModel) {
        // If window exists and is visible, just bring it front
        if let window = window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: settingsView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 480, height: 360)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Drip Settings"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: .mock())
    }
}
#endif
