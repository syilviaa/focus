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
        
        // Add today to completion history
        tasks[index].completionHistory.insert(today)
        tasks[index].lastCompletionDate = Date()
        
        // Calculate streak: count consecutive days ending at today
        var currentStreak = 0
        var checkDate = today
        
        while tasks[index].completionHistory.contains(checkDate) {
            currentStreak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        
        tasks[index].streak = currentStreak
    }
    
    /// Check each task for broken streaks.
    /// A streak is broken if yesterday is NOT in the completion history,
    /// meaning the user let the entire next day pass without completing.
    private func checkForBrokenStreaks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }
        
        var changed = false
        for i in 0..<tasks.count {
            if tasks[i].streak > 0 {
                // If yesterday is not in the completion history, the streak is broken
                let yesterdayStart = calendar.startOfDay(for: yesterday)
                if !tasks[i].completionHistory.contains(yesterdayStart) {
                    // Also check if they already completed today (streak would still be valid)
                    if !tasks[i].completionHistory.contains(today) {
                        tasks[i].streak = 0
                        changed = true
                    }
                }
            }
        }
        if changed {
            saveTasks()
        }
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
                // It's a new day! Reset completion status but keep tasks
                for i in 0..<tasks.count {
                    tasks[i].isCompleted = false
                }
                
                // Check and break streaks for tasks not completed yesterday
                checkForBrokenStreaks()
                
                saveTasks()
                UserDefaults.standard.set(today, forKey: "last_refresh_date")
            }
        } else {
            // First launch — also check for any broken streaks
            checkForBrokenStreaks()
            UserDefaults.standard.set(today, forKey: "last_refresh_date")
        }
    }
    
    private func updateGlobalStreak() {
        // Global streak is the highest task streak
        self.streak = tasks.map { $0.streak }.max() ?? 0
        UserDefaults.standard.set(self.streak, forKey: streakKey)
    }
    
    private func calculateStreak() {
        // Recalculate global streak + check for broken streaks on app launch
        checkForBrokenStreaks()
        updateGlobalStreak()
    }
}
