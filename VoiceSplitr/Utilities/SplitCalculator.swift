import Foundation

struct PersonSplit: Identifiable {
    let id: UUID
    let name: String
    let items: [(name: String, amount: Double)]
    let itemsSubtotal: Double
    let taxShare: Double
    let tipShare: Double
    let total: Double
}

struct SplitCalculator {

    static func calculateSplits(
        lineItems: [LineItem],
        taxAmount: Double,
        tipAmount: Double
    ) -> [PersonSplit] {
        // Build a map of person ID -> (name, [(itemName, shareAmount)])
        var personItems: [UUID: (name: String, items: [(String, Double)])] = [:]

        for item in lineItems {
            let assignees = item.assignedTo
            guard !assignees.isEmpty else { continue }

            let sharePerPerson = item.totalPrice / Double(assignees.count)

            for person in assignees {
                if personItems[person.id] == nil {
                    personItems[person.id] = (name: person.name, items: [])
                }
                personItems[person.id]?.items.append((item.name, sharePerPerson))
            }
        }

        // Handle unassigned items: split equally among all people
        let unassignedItems = lineItems.filter { $0.assignedTo.isEmpty }
        if !unassignedItems.isEmpty && !personItems.isEmpty {
            let allPersonIDs = Array(personItems.keys)
            for item in unassignedItems {
                let sharePerPerson = item.totalPrice / Double(allPersonIDs.count)
                for personID in allPersonIDs {
                    personItems[personID]?.items.append((item.name, sharePerPerson))
                }
            }
        }

        let subtotal = lineItems.reduce(0.0) { $0 + $1.totalPrice }
        guard subtotal > 0 else {
            return personItems.map { (id, value) in
                PersonSplit(
                    id: id,
                    name: value.name,
                    items: value.items.map { (name: $0.0, amount: $0.1) },
                    itemsSubtotal: 0,
                    taxShare: 0,
                    tipShare: 0,
                    total: 0
                )
            }
        }

        var splits: [PersonSplit] = []
        var runningTotal = 0.0

        let sortedPersons = personItems.sorted { $0.key.uuidString < $1.key.uuidString }

        for (index, (id, value)) in sortedPersons.enumerated() {
            let itemsSubtotal = value.items.reduce(0.0) { $0 + $1.1 }
            let proportion = itemsSubtotal / subtotal

            let taxShare: Double
            let tipShare: Double

            if index == sortedPersons.count - 1 {
                // Last person gets the remainder to handle rounding
                taxShare = taxAmount - splits.reduce(0.0) { $0 + $1.taxShare }
                tipShare = tipAmount - splits.reduce(0.0) { $0 + $1.tipShare }
            } else {
                taxShare = (proportion * taxAmount * 100).rounded() / 100
                tipShare = (proportion * tipAmount * 100).rounded() / 100
            }

            let total = ((itemsSubtotal + taxShare + tipShare) * 100).rounded() / 100

            splits.append(PersonSplit(
                id: id,
                name: value.name,
                items: value.items.map { (name: $0.0, amount: $0.1) },
                itemsSubtotal: (itemsSubtotal * 100).rounded() / 100,
                taxShare: taxShare,
                tipShare: tipShare,
                total: total
            ))

            runningTotal += total
        }

        return splits
    }
}
