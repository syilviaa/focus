import SwiftUI

public struct TaskListView: View {
    @ObservedObject var store: FocusStore
    @State private var newTaskTitle: String = ""
    
    public init(store: FocusStore) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Streak Header
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(store.streak) Day Streak")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(Date().formatted(.dateTime.weekday().day().month()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            Divider()
            
            // Add Task Input
            HStack {
                TextField("What are you focusing on today?", text: $newTaskTitle, onCommit: {
                    if !newTaskTitle.isEmpty {
                        store.addTask(title: newTaskTitle)
                        newTaskTitle = ""
                    }
                })
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                
                Button(action: {
                    if !newTaskTitle.isEmpty {
                        store.addTask(title: newTaskTitle)
                        newTaskTitle = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            
            // Task List
            if store.tasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checklist")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("No tasks added for today.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(store.tasks) { task in
                            TaskRowView(task: task) {
                                store.toggleTask(task)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: .infinity)
            }
            
            Button("Clear All") {
                store.tasks = []
            }
            .buttonStyle(.borderless)
            .padding(.bottom, 8)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(width: 300, height: 400)
        .background(VisualEffectView(material: .menu, blendingMode: .behindWindow))
    }
}

struct TaskRowView: View {
    let task: FocusTask
    let toggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .accentColor)
                .font(.title3)
            
            Text(task.title)
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(task.isCompleted ? Color.green.opacity(0.1) : Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(task.isCompleted ? Color.green.opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .onTapGesture {
            toggle()
        }
    }
}

// Helper for blurry background
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
