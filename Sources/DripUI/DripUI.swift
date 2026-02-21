import Foundation
import Drip
import DripEngine

/// DripUI — SwiftUI views for the menu bar app.
/// This module provides the menu bar icon, popover, settings window,
/// and all user-facing interface components.
///
/// Public API:
/// - ``DripViewModel`` — Main view model for all UI state
/// - ``MenuBarIconView`` — Menu bar droplet icon
/// - ``PopoverView`` — Connected state popover
/// - ``NotConnectedView`` — Disconnected state popover
/// - ``SettingsView`` — Settings window with tabs
/// - ``UsageProgressBar`` — Reusable progress bar
/// - ``ByteFormatter`` — Byte count formatting
/// - ``FillLevel`` — Usage ratio calculation
/// - ``UsageLevel`` — Color threshold enum
/// - ``DisplayFormat`` — User display preference
public enum DripUI {
    public static let version = "0.1.0"
}
