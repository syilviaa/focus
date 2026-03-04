import SwiftUI

@main
struct FocusApp: App {
    @StateObject private var store = FocusStore()
    
    var body: some Scene {
        MenuBarExtra("Focus Tracker", systemImage: "target") {
            TaskListView(store: store)
        }
        .menuBarExtraStyle(.window) 
        
        WindowGroup {
            TaskListView(store: store)
                .onAppear {
                }
        }
    }
}
