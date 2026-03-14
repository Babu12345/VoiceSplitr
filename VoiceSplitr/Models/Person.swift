import Foundation
import SwiftData

@Model
final class Person {
    var id: UUID
    var name: String
    var shareAmount: Double

    var session: SplitSession?
    var assignedItems: [LineItem]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.shareAmount = 0
        self.assignedItems = []
    }
}
