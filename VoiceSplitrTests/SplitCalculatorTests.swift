//
//  SplitCalculatorTests.swift
//  VoiceSplitrTests
//

import Foundation
import Testing
import SwiftData
@testable import VoiceSplitr

@MainActor
struct SplitCalculatorTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: SplitSession.self, LineItem.self, Person.self, VoiceTranscript.self,
            configurations: config
        )
    }

    private func makeItem(
        _ name: String,
        _ price: Double,
        assignedTo: [Person] = [],
        in context: ModelContext
    ) -> LineItem {
        let item = LineItem(name: name, price: price)
        context.insert(item)
        item.assignedTo = assignedTo
        return item
    }

    private func makePerson(_ name: String, in context: ModelContext) -> Person {
        let p = Person(name: name)
        context.insert(p)
        return p
    }

    // MARK: - Tests

    @Test func emptyInputsReturnEmpty() async throws {
        let splits = SplitCalculator.calculateSplits(lineItems: [], taxAmount: 0, tipAmount: 0)
        #expect(splits.isEmpty)
    }

    @Test func unassignedOnlyReturnsEmpty() async throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let item = makeItem("Burger", 10, in: ctx)

        let splits = SplitCalculator.calculateSplits(lineItems: [item], taxAmount: 1, tipAmount: 1)
        #expect(splits.isEmpty)
    }

    @Test func singlePersonGetsEverything() async throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let alice = makePerson("Alice", in: ctx)
        let item = makeItem("Pizza", 20, assignedTo: [alice], in: ctx)

        let splits = SplitCalculator.calculateSplits(
            lineItems: [item], taxAmount: 2, tipAmount: 3
        )

        #expect(splits.count == 1)
        let s = splits[0]
        #expect(s.name == "Alice")
        #expect(s.itemsSubtotal == 20)
        #expect(s.taxShare == 2)
        #expect(s.tipShare == 3)
        #expect(s.total == 25)
    }

    @Test func sharedItemSplitsEvenly() async throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let a = makePerson("Alice", in: ctx)
        let b = makePerson("Bob", in: ctx)
        let shared = makeItem("Nachos", 10, assignedTo: [a, b], in: ctx)

        let splits = SplitCalculator.calculateSplits(
            lineItems: [shared], taxAmount: 0, tipAmount: 0
        )

        #expect(splits.count == 2)
        #expect(splits.allSatisfy { $0.itemsSubtotal == 5 })
        #expect(splits.allSatisfy { $0.total == 5 })
    }

    @Test func taxAndTipSplitProportionally() async throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let a = makePerson("Alice", in: ctx)
        let b = makePerson("Bob", in: ctx)
        let i1 = makeItem("Steak", 30, assignedTo: [a], in: ctx)
        let i2 = makeItem("Salad", 10, assignedTo: [b], in: ctx)

        let splits = SplitCalculator.calculateSplits(
            lineItems: [i1, i2], taxAmount: 4, tipAmount: 8
        )

        #expect(splits.count == 2)
        let total = splits.reduce(0.0) { $0 + $1.total }
        // 40 + 4 + 8 = 52
        #expect(abs(total - 52.0) < 0.0001)

        let totalTax = splits.reduce(0.0) { $0 + $1.taxShare }
        let totalTip = splits.reduce(0.0) { $0 + $1.tipShare }
        #expect(abs(totalTax - 4.0) < 0.0001)
        #expect(abs(totalTip - 8.0) < 0.0001)
    }

    @Test func unassignedItemsSplitAmongAllAssignedPeople() async throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let a = makePerson("Alice", in: ctx)
        let b = makePerson("Bob", in: ctx)
        let assigned = makeItem("Burger", 10, assignedTo: [a], in: ctx)
        let assigned2 = makeItem("Fries", 10, assignedTo: [b], in: ctx)
        let unassigned = makeItem("Soda", 4, in: ctx)

        let splits = SplitCalculator.calculateSplits(
            lineItems: [assigned, assigned2, unassigned], taxAmount: 0, tipAmount: 0
        )

        #expect(splits.count == 2)
        // Each person: own item (10) + half of soda (2) = 12
        #expect(splits.allSatisfy { $0.itemsSubtotal == 12 })
        let total = splits.reduce(0.0) { $0 + $1.total }
        #expect(abs(total - 24.0) < 0.0001)
    }

    @Test func roundingRemainderGoesToLastPerson() async throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        // 3 people, $10 tax that doesn't divide evenly
        let a = makePerson("Alice", in: ctx)
        let b = makePerson("Bob", in: ctx)
        let c = makePerson("Carol", in: ctx)
        let i1 = makeItem("A", 10, assignedTo: [a], in: ctx)
        let i2 = makeItem("B", 10, assignedTo: [b], in: ctx)
        let i3 = makeItem("C", 10, assignedTo: [c], in: ctx)

        let splits = SplitCalculator.calculateSplits(
            lineItems: [i1, i2, i3], taxAmount: 10, tipAmount: 0
        )

        let totalTax = splits.reduce(0.0) { $0 + $1.taxShare }
        #expect(abs(totalTax - 10.0) < 0.0001)
    }

    @Test func zeroSubtotalReturnsZeroedSplits() async throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let a = makePerson("Alice", in: ctx)
        let item = makeItem("Free", 0, assignedTo: [a], in: ctx)

        let splits = SplitCalculator.calculateSplits(
            lineItems: [item], taxAmount: 5, tipAmount: 5
        )

        #expect(splits.count == 1)
        #expect(splits[0].total == 0)
        #expect(splits[0].taxShare == 0)
        #expect(splits[0].tipShare == 0)
    }
}
