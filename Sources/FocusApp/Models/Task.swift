import Foundation

public struct FocusTask: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool
    public var createdDate: Date
    public var streak: Int
    public var lastCompletionDate: Date?
    public var completionHistory: Set<Date>
    
    public init(id: UUID = UUID(), 
                title: String, 
                isCompleted: Bool = false, 
                createdDate: Date = Date(),
                streak: Int = 0,
                lastCompletionDate: Date? = nil,
                completionHistory: Set<Date> = []) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdDate = createdDate
        self.streak = streak
        self.lastCompletionDate = lastCompletionDate
        self.completionHistory = completionHistory
    }
}
