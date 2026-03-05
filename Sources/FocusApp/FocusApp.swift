import SwiftUI

@main
struct FocusApp: App {
    @StateObject private var store = FocusStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        // Dashboard
        Window("Focus Dashboard", id: "dashboard") {
            DashboardView(store: store)
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
                    if let window = notification.object as? NSWindow, window.title == "Focus Dashboard" {
                        // When dashboard closes, ensure we are in accessory mode
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
        }
        
        // Widget
        Window("Focus Widget", id: "widget") {
            TaskListView(store: store)
                .background(WidgetWindowConfigurator())
                .ignoresSafeArea()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        // Menu Bar Extra for persistent access
        MenuBarExtra("Focus", systemImage: "target") {
            Button("Show Dashboard") {
                NSApp.setActivationPolicy(.regular)
                openWindow(id: "dashboard")
                NSApp.activate(ignoringOtherApps: true)
            }
            Button("Show Widget") {
                openWindow(id: "widget")
            }
            Divider()
            Button("Quit Focus") {
                NSApp.terminate(nil)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start as accessory if we want background behavior, 
        // but .regular if we want to show in Dock for the first launch.
        // Given it's a widget app, accessory is safer for "always on top".
        NSApp.setActivationPolicy(.accessory)
    }
}

// Custom View to configure the parent window for widget behavior
struct WidgetWindowConfigurator: NSViewRepresentable {
    class ConfigView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            configureWindow()
        }
        
        func configureWindow() {
            guard let window = self.window else { return }
            
            // Basic setup
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = true
            window.hidesOnDeactivate = false
            window.isReleasedWhenClosed = false
            window.isMovableByWindowBackground = true
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isExcludedFromWindowsMenu = true
            
            // Hide standard buttons
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            
            // Initial application of behavior
            applyWidgetBehavior(to: window)
            
            // Periodically re-apply slightly to fight off SwiftUI's aggressive window resets
            // especially after space transitions or fullscreen changes.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.applyWidgetBehavior(to: window)
            }
            
            // One more just to be absolutely sure after the window is fully layered
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.applyWidgetBehavior(to: window)
            }
        }
        
        private func applyWidgetBehavior(to window: NSWindow) {
            // .statusBar level (25) is ideal for hovering over fullscreen apps
            window.level = .statusBar
            
            // .canJoinAllSpaces: stay visible on all desktops
            // .fullScreenAuxiliary: hover over full-screen apps
            // .ignoresCycle: don't show in Cmd+Tab or window cycling
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
            
            // Ensure resizability is active
            if !window.styleMask.contains(.resizable) {
                window.styleMask.insert(.resizable)
            }
            
            // Ensure it doesn't hide when other apps are fullscreen
            window.hidesOnDeactivate = false
        }
    }
    
    func makeNSView(context: Context) -> NSView {
        return ConfigView()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let configView = nsView as? ConfigView {
            configView.configureWindow()
        }
    }
}
