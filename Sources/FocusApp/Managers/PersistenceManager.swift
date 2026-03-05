import Foundation
import Combine

public class FocusStore: ObservableObject {
    @Published public var tasks: [FocusTask] = []
    @Published public var streak: Int = 0
    
    private let tasksKey = "focus_tasks"
    private let streakKey = "focus_streak"
    private let lastCompletionDateKey = "focus_last_completion_date"
    private let completionHistoryKey = "focus_completion_history"
    
    private var timer: AnyCancellable?
    
    public init() {
        self.loadTasks()
        self.refreshDailyTasks()
        self.calculateStreak()
        self.setupTimer()
    }
    
    private func setupTimer() {
        timer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshDailyTasks()
            }
    }
    
    public func addTask(title: String) {
        let newTask = FocusTask(title: title)
        tasks.append(newTask)
        saveTasks()
    }
    
    public func toggleTask(_ task: FocusTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            let wasCompleted = tasks[index].isCompleted
            tasks[index].isCompleted.toggle()
            
            if !wasCompleted && tasks[index].isCompleted {
                // Task was just completed
                updateTaskStreak(at: index)
            }
            
            saveTasks()
            updateGlobalStreak()
        }
    }
    
    public func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        saveTasks()
        updateGlobalStreak()
    }
    
    private func updateTaskStreak(at index: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Add to history if not already there
        tasks[index].completionHistory.insert(today)
        tasks[index].lastCompletionDate = Date()
        
        // Calculate new streak for this task
        var currentStreak = 0
        var checkDate = today
        
        while tasks[index].completionHistory.contains(checkDate) {
            currentStreak += 1
            guard let nextDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = nextDate
        }
        
        tasks[index].streak = currentStreak
    }
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([FocusTask].self, from: data) {
            self.tasks = decoded
        }
    }
    
    private func refreshDailyTasks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastRefresh = UserDefaults.standard.object(forKey: "last_refresh_date") as? Date {
            if !calendar.isDate(lastRefresh, inSameDayAs: today) {
                // It's a new day! Reset completion but keep tasks for streaks
                for i in 0..<tasks.count {
                    tasks[i].isCompleted = false
                }
                saveTasks()
                UserDefaults.standard.set(today, forKey: "last_refresh_date")
            }
        } else {
            UserDefaults.standard.set(today, forKey: "last_refresh_date")
        }
    }
    
    private func updateGlobalStreak() {
        // Global streak is the highest task streak
        self.streak = tasks.map { $0.streak }.max() ?? 0
        UserDefaults.standard.set(self.streak, forKey: streakKey)
    }
    
    private func calculateStreak() {
        // Just refresh global streak from tasks
        updateGlobalStreak()
    }
}
