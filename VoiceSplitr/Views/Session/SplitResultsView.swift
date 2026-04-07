import SwiftUI

struct SplitResultsView: View {
    @Bindable var viewModel: NewSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var editModel = EditAssignmentModel()
    @State private var newPersonName = ""

    var body: some View {
        List {
            if isEditing {
                editingContent
            } else {
                resultsContent
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        applyEdits()
                    } else {
                        startEditing()
                    }
                }
            }
        }
    }

    // MARK: - Results View

    @ViewBuilder
    private var resultsContent: some View {
        ForEach(viewModel.splits) { split in
            PersonSplitCard(split: split)
        }

        Section {
            HStack {
                Text("Grand Total")
                    .font(.headline)
                Spacer()
                Text("$\(String(format: "%.2f", viewModel.splits.reduce(0) { $0 + $1.total }))")
                    .font(.headline)
                    .foregroundStyle(Color.brandBlue)
            }
        }

        Section {
            Button {
                viewModel.currentStep = .share
            } label: {
                Label("Share Results", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.primary)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Button {
                _ = viewModel.saveSession(to: modelContext)
                dismiss()
            } label: {
                Label("Save & Close", systemImage: "checkmark.circle")
            }
            .buttonStyle(.secondary)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Editing View

    @ViewBuilder
    private var editingContent: some View {
        Section("People") {
            ForEach(editModel.people) { person in
                HStack {
                    TextField("Name", text: Binding(
                        get: {
                            editModel.people.first(where: { $0.id == person.id })?.name ?? ""
                        },
                        set: { newName in
                            editModel.renamePerson(id: person.id, to: newName)
                        }
                    ))
                    .textInputAutocapitalization(.words)

                    Button(role: .destructive) {
                        editModel.removePerson(id: person.id)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                TextField("Add person", text: $newPersonName)
                    .textInputAutocapitalization(.words)
                    .onSubmit { addPerson() }

                Button {
                    addPerson()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(newPersonName.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : Color.brandBlue)
                }
                .buttonStyle(.plain)
                .disabled(newPersonName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }

        ForEach(editModel.items) { editItem in
            Section {
                HStack {
                    Text(editItem.name)
                        .font(.headline)
                    if editItem.quantity > 1 {
                        Text("x\(editItem.quantity)")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("$\(String(format: "%.2f", editItem.price))")
                        .foregroundStyle(.secondary)
                }

                ForEach(editModel.people) { person in
                    Button {
                        editModel.toggle(item: editItem.name, personID: person.id)
                    } label: {
                        HStack {
                            Image(systemName: editModel.isAssigned(item: editItem.name, personID: person.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(editModel.isAssigned(item: editItem.name, personID: person.id) ? Color.brandBlue : .secondary)
                            Text(person.name)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Edit Actions

    private func startEditing() {
        editModel = EditAssignmentModel(
            items: viewModel.editableItems,
            people: viewModel.assignmentResult?.people.sorted() ?? [],
            assignments: viewModel.assignmentResult?.assignments ?? []
        )
        isEditing = true
    }

    private func applyEdits() {
        var result = viewModel.assignmentResult ?? BillAssignmentResult(assignments: [], people: [])
        result.assignments = editModel.toAssignments()
        result.people = editModel.people.map { $0.name }
        viewModel.assignmentResult = result
        viewModel.calculateFinalSplits()
        isEditing = false
    }

    private func addPerson() {
        let name = newPersonName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !editModel.people.contains(where: { $0.name == name }) else { return }
        editModel.addPerson(name)
        newPersonName = ""
    }
}

// MARK: - Edit Model

@Observable
class EditAssignmentModel {
    struct EditItem: Identifiable {
        let id: UUID
        let name: String
        let price: Double
        let quantity: Int
    }

    struct PersonEntry: Identifiable, Hashable {
        let id: UUID
        var name: String
    }

    var items: [EditItem] = []
    var people: [PersonEntry] = []
    var assignments: [String: [UUID: Bool]] = [:]  // [itemName: [personID: Bool]]

    init() {}

    init(items: [ParsedLineItem], people: [String], assignments: [ItemAssignment]) {
        self.items = items.map { EditItem(id: $0.id, name: $0.name, price: $0.price, quantity: $0.quantity) }
        self.people = people.map { PersonEntry(id: UUID(), name: $0) }

        for item in items {
            var personMap: [UUID: Bool] = [:]
            let assignment = assignments.first { $0.itemName == item.name }
            for person in self.people {
                personMap[person.id] = assignment?.assignedTo.contains(person.name) ?? false
            }
            self.assignments[item.name] = personMap
        }
    }

    func isAssigned(item: String, personID: UUID) -> Bool {
        assignments[item]?[personID] ?? false
    }

    func toggle(item: String, personID: UUID) {
        let current = assignments[item]?[personID] ?? false
        assignments[item]?[personID] = !current
    }

    func renamePerson(id: UUID, to newName: String) {
        guard let idx = people.firstIndex(where: { $0.id == id }) else { return }
        people[idx].name = newName
    }

    func addPerson(_ name: String) {
        let entry = PersonEntry(id: UUID(), name: name)
        people.append(entry)
        for item in items {
            assignments[item.name]?[entry.id] = false
        }
    }

    func removePerson(id: UUID) {
        people.removeAll { $0.id == id }
        for item in items {
            assignments[item.name]?[id] = nil
        }
    }

    func toAssignments() -> [ItemAssignment] {
        items.map { item in
            let assigned = people
                .filter { assignments[item.name]?[$0.id] == true }
                .map { $0.name }
            return ItemAssignment(itemName: item.name, assignedTo: assigned)
        }
    }
}
