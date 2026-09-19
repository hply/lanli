import SwiftUI

@main
struct LanliApp: App {
    @StateObject private var store = AppState()

    var body: some Scene {
        MenuBarExtra {
            CalendarPopupView()
                .environmentObject(store)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)

        Settings {
            HolidayEditorView()
                .environmentObject(store)
                .frame(width: 520, height: 640)
        }
    }
}

private struct MenuBarLabel: View {
    @ObservedObject var store: AppState

    var body: some View {
        if store.menuFormat == .icon {
            Image(systemName: "calendar")
        } else {
            Text(store.menuTitle)
                .font(.system(size: 13, weight: .medium))
        }
    }
}
