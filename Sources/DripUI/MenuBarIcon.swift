import SwiftUI
import Drip

// MARK: - Menu Bar Icon View

public struct MenuBarIconView: View {
    let connectionState: ConnectionState
    let usageRatio: Double
    let showUsageText: Bool
    let formattedUsage: String

    public init(
        connectionState: ConnectionState,
        usageRatio: Double,
        showUsageText: Bool = false,
        formattedUsage: String = ""
    ) {
        self.connectionState = connectionState
        self.usageRatio = usageRatio
        self.showUsageText = showUsageText
        self.formattedUsage = formattedUsage
    }

    private var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }

    private var iconColor: Color {
        switch UsageLevel.from(ratio: usageRatio) {
        case .normal: return .blue
        case .warning: return .yellow
        case .critical: return .red
        }
    }

    public var body: some View {
        HStack(spacing: 4) {
            dropletIcon
            if showUsageText && isConnected {
                Text(formattedUsage)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .monospacedDigit()
            }
        }
    }

    @ViewBuilder
    private var dropletIcon: some View {
        if isConnected {
            FillingDropletIcon(ratio: usageRatio, color: iconColor)
                .frame(width: 14, height: 16)
        } else {
            Image(systemName: "drop")
                .foregroundStyle(.secondary)
                .imageScale(.medium)
        }
    }
}

// MARK: - Filling Droplet Icon

/// A water-droplet glyph that fills from the bottom in proportion to data
/// usage. The empty outline is always drawn; a coloured fill rises to
/// `ratio` (0...1) and animates smoothly as usage changes — the visual
/// signature of the app ("Drip").
public struct FillingDropletIcon: View {
    public let ratio: Double
    public let color: Color

    public init(ratio: Double, color: Color) {
        self.ratio = ratio
        self.color = color
    }

    private var clampedRatio: CGFloat {
        CGFloat(min(max(ratio, 0), 1))
    }

    public var body: some View {
        GeometryReader { geo in
            let height = geo.size.height

            ZStack(alignment: .bottom) {
                // Faint outline so an empty droplet is still legible.
                Image(systemName: "drop.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(color.opacity(0.25))

                // Coloured fill rising from the bottom, masked to the droplet.
                Image(systemName: "drop.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(color)
                    .mask(alignment: .bottom) {
                        Rectangle()
                            .frame(height: height * clampedRatio)
                    }
            }
            .animation(.easeInOut(duration: 0.4), value: clampedRatio)
        }
    }
}

// MARK: - Menu Bar Image Rendering

public struct MenuBarImageRenderer {
    /// Renders the menu bar icon as an NSImage suitable for the status bar.
    @MainActor
    public static func renderImage(
        connectionState: ConnectionState,
        usageRatio: Double,
        showUsageText: Bool,
        formattedUsage: String
    ) -> NSImage {
        let view = MenuBarIconView(
            connectionState: connectionState,
            usageRatio: usageRatio,
            showUsageText: showUsageText,
            formattedUsage: formattedUsage
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0

        guard let cgImage = renderer.cgImage else {
            return NSImage(systemSymbolName: "drop", accessibilityDescription: "Drip")
                ?? NSImage()
        }

        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width / 2, height: cgImage.height / 2))
        image.isTemplate = false
        return image
    }
}

// MARK: - Preview

#if DEBUG
struct MenuBarIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                FillingDropletIcon(ratio: 0.0, color: .blue).frame(width: 18, height: 22)
                FillingDropletIcon(ratio: 0.4, color: .blue).frame(width: 18, height: 22)
                FillingDropletIcon(ratio: 0.8, color: .yellow).frame(width: 18, height: 22)
                FillingDropletIcon(ratio: 1.0, color: .red).frame(width: 18, height: 22)
            }
            Divider()
            MenuBarIconView(
                connectionState: .disconnected,
                usageRatio: 0
            )
            MenuBarIconView(
                connectionState: .connected(hotspotName: "iPhone", interfaceName: "en1"),
                usageRatio: 0.25
            )
            MenuBarIconView(
                connectionState: .connected(hotspotName: "iPhone", interfaceName: "en1"),
                usageRatio: 0.8,
                showUsageText: true,
                formattedUsage: "8.0 GB"
            )
            MenuBarIconView(
                connectionState: .connected(hotspotName: "iPhone", interfaceName: "en1"),
                usageRatio: 0.95,
                showUsageText: true,
                formattedUsage: "9.5 GB"
            )
        }
        .padding()
    }
}
#endif
