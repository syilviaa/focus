import Foundation

public struct FocusTask: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool
    public var createdDate: Date
    
    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdDate: Date = Date()) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdDate = createdDate
    }
}
