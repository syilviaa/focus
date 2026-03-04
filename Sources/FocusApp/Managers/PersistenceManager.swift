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
            tasks[index].isCompleted.toggle()
            saveTasks()
            updateStreakOnCompletion()
        }
    }
    
    public func deleteTask(at indexSet: IndexSet) {
        tasks.remove(atOffsets: indexSet)
        saveTasks()
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
                tasks = [] 
                saveTasks()
                UserDefaults.standard.set(today, forKey: "last_refresh_date")
            }
        } else {
            UserDefaults.standard.set(today, forKey: "last_refresh_date")
        }
    }
    
    private func updateStreakOnCompletion() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let anyCompletedToday = tasks.contains { $0.isCompleted }
        
        if anyCompletedToday {
            var history = getCompletionHistory()
            history.insert(today)
            saveCompletionHistory(history)
            calculateStreak()
        }
    }
    
    private func getCompletionHistory() -> Set<Date> {
        if let data = UserDefaults.standard.array(forKey: completionHistoryKey) as? [Date] {
            return Set(data)
        }
        return []
    }
    
    private func saveCompletionHistory(_ history: Set<Date>) {
        UserDefaults.standard.set(Array(history), forKey: completionHistoryKey)
    }
    
    private func calculateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        var history = getCompletionHistory()
        var currentStreak = 0
        var checkDate = today
        
        if !history.contains(today) {
            checkDate = yesterday
        }
        
        while history.contains(checkDate) {
            currentStreak += 1
            guard let nextCheckDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = nextCheckDate
        }
        
        self.streak = currentStreak
        UserDefaults.standard.set(self.streak, forKey: streakKey)
    }
}
