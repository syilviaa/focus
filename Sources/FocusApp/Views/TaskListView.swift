import SwiftUI

public struct TaskListView: View {
    @ObservedObject var store: FocusStore
    @State private var newTaskTitle: String = ""
    @State private var isAnimating = false
    
    @FocusState private var isFieldFocused: Bool
    
    public init(store: FocusStore) {
        self.store = store
    }
    
    public var body: some View {
        ZStack {
            // Background is now fully transparent via the window helper
            
            VStack(spacing: 0) {
                // Drag Handle / Header Area
                HStack {
                    Spacer()
                    Capsule()
                        .fill(Color.primary.opacity(0.2))
                        .frame(width: 30, height: 4)
                        .padding(.top, 8)
                    Spacer()
                }
                .background(Color.clear) // Helpful for dragging
                
                VStack(spacing: 8) {
                    // Task List
                    if store.tasks.isEmpty {
                        Spacer()
                        Text("No tasks")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(.primary.opacity(0.8))
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 6) {
                                ForEach(store.tasks) { task in
                                    TaskRowView(task: task, 
                                              onToggle: { withAnimation(.spring(response: 0.3)) { store.toggleTask(task) } },
                                              onDelete: { withAnimation { store.deleteTask(id: task.id) } })
                                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .slide.combined(with: .opacity)))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.top, 10)
                        }
                    }
                    
                    // Extremely Minimal Input
                    TextField("Add task...", text: $newTaskTitle)
                        .textFieldStyle(.plain)
                        .focused($isFieldFocused)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .padding(8)
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 10)
                        .onSubmit {
                            addNewTask()
                        }
                    
                    // Minimal Date at Bottom
                    Text(Date().formatted(.dateTime.weekday().day().month()))
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundColor(.primary.opacity(0.6))
                        .padding(.bottom, 10)
                }
                .padding(.top, 4)
            }
            .background(
                ZStack {
                    VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.primary.opacity(0.3), lineWidth: 2)
                }
            )
        }
        .frame(minWidth: 160, maxWidth: 400, minHeight: 180, maxHeight: 800)
    }
    
    private func addNewTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        // Clear text field IMMEDIATELY to satisfy the user request for zero delay
        newTaskTitle = ""
        
        if !title.isEmpty {
            // Task addition happens in background to keep UI snappy
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    store.addTask(title: title)
                }
            }
        }
    }
}

struct TaskRowView: View {
    let task: FocusTask
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var streakScale: CGFloat = 1.0
    
    /// Streak color tiers:
    /// - Default (1-29): Orange 🔥
    /// - 30+: Blue 💙
    /// - 90+: Purple 💜
    /// - 360+: Red ❤️‍🔥
    private var streakColor: Color {
        let s = task.streak
        if s >= 360 {
            return .red
        } else if s >= 90 {
            return .purple
        } else if s >= 30 {
            return Color(red: 0.2, green: 0.5, blue: 1.0) // Blueish
        } else {
            return .orange
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Task Toggle Button
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(task.isCompleted ? .green : .accentColor)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(task.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .primary.opacity(0.4) : .primary)
                
                if task.streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                        Text("\(task.streak)")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                    }
                    .foregroundColor(streakColor)
                    .scaleEffect(streakScale)
                    .onChange(of: task.streak) { oldValue, newValue in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                            streakScale = 1.3
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation { streakScale = 1.0 }
                        }
                    }
                }
            }
            
            Spacer()
            
            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.04)) // Subtle background for better readability
        .cornerRadius(10)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
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
