import SwiftUI
import Drip
import DripEngine
import DripUI

@main
struct DripApp: App {
    @StateObject private var viewModel = DripViewModel.live()

    var body: some Scene {
        MenuBarExtra {
            Group {
                if viewModel.isConnected {
                    PopoverView(viewModel: viewModel)
                } else {
                    NotConnectedView(viewModel: viewModel)
                }
            }
        } label: {
            MenuBarIconView(
                connectionState: viewModel.connectionState,
                usageRatio: viewModel.usageRatio,
                showUsageText: viewModel.showUsageInMenuBar,
                formattedUsage: viewModel.formattedUsage
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: viewModel)
        }
    }
}
