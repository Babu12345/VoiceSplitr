import Foundation
import SwiftData

@Model
final class LineItem {
    var id: UUID
    var name: String
    var price: Double
    var quantity: Int

    var session: SplitSession?

    @Relationship(inverse: \Person.assignedItems)
    var assignedTo: [Person]

    var totalPrice: Double {
        price * Double(quantity)
    }

    init(name: String, price: Double, quantity: Int = 1) {
        self.id = UUID()
        self.name = name
        self.price = price
        self.quantity = quantity
        self.assignedTo = []
    }
}
