import Foundation

struct ParsedReceipt: Codable {
    var items: [ParsedLineItem]
    var subtotal: Double?
    var tax: Double?
    var total: Double?
}

struct ParsedLineItem: Codable, Identifiable {
    var id = UUID()
    var name: String
    var price: Double
    var quantity: Int

    enum CodingKeys: String, CodingKey {
        case name, price, quantity
    }

    init(name: String, price: Double, quantity: Int = 1) {
        self.name = name
        self.price = price
        self.quantity = quantity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.price = try container.decode(Double.self, forKey: .price)
        self.quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
    }
}

struct BillAssignmentResult: Codable {
    var assignments: [ItemAssignment]
    var people: [String]
}

struct ItemAssignment: Codable {
    var itemName: String
    var assignedTo: [String]

    enum CodingKeys: String, CodingKey {
        case itemName = "item_name"
        case assignedTo = "assigned_to"
    }

    init(itemName: String, assignedTo: [String]) {
        self.itemName = itemName
        self.assignedTo = assignedTo
    }
}
