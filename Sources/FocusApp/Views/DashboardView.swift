import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: FocusStore
    @Environment(\.openWindow) private var openWindow
    @State private var isWidgetEnabled = true
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Focus")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                    Text("Daily consistency made simple.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "target")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
            }
            .padding(.top, 20)
            
            Divider()
            
            // How to use
            VStack(alignment: .leading, spacing: 16) {
                Text("How to use")
                    .font(.headline)
                
                InstructionRow(icon: "1.circle.fill", text: "Position your transparent widget anywhere on the desktop by dragging the 'Focus' text.")
                InstructionRow(icon: "2.circle.fill", text: "Add tasks by typing in the widget and pressing Enter.")
                InstructionRow(icon: "3.circle.fill", text: "Complete tasks daily to build your flame streak. Streaks are unique to each task!")
                InstructionRow(icon: "4.circle.fill", text: "Hover over a task in the widget to reveal the delete button.")
                InstructionRow(icon: "5.circle.fill", text: "Access the menu bar icon (target icon) to reopen the dashboard or quit the app anytime.")
            }
            
            Spacer()
            
            // Settings/Actions
            VStack(spacing: 12) {
                Button(action: {
                    openWindow(id: "widget")
                }) {
                    Label("Show Widget", systemImage: "app.badge")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                HStack(spacing: 12) {
                    Button(action: {
                        NSApp.terminate(nil)
                    }) {
                        Label("Quit App", systemImage: "power")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            .padding(.bottom, 20)
        }
        .padding(30)
        .frame(width: 500, height: 500)
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.title3)
            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}
