import SwiftUI

struct SplitResultsView: View {
    @Bindable var viewModel: NewSessionViewModel
    @State private var isEditing = false
    @State private var editableAssignments: [String: Set<String>] = [:]  // itemName -> Set<personName>

    var body: some View {
        List {
            if isEditing {
                editingContent
            } else {
                resultsContent
            }
        }
        .animation(.default, value: isEditing)
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
            }
        }

        Section {
            Button {
                viewModel.currentStep = .share
            } label: {
                HStack {
                    Spacer()
                    Label("Share Results", systemImage: "square.and.arrow.up")
                        .font(.headline)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Editing View

    @ViewBuilder
    private var editingContent: some View {
        let people = viewModel.assignmentResult?.people ?? []

        ForEach(viewModel.editableItems) { item in
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                        if item.quantity > 1 {
                            Text("x\(item.quantity)")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("$\(String(format: "%.2f", item.price * Double(item.quantity)))")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(people, id: \.self) { person in
                        let isAssigned = editableAssignments[item.name]?.contains(person) ?? false
                        Button {
                            toggleAssignment(item: item.name, person: person)
                        } label: {
                            HStack {
                                Image(systemName: isAssigned ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isAssigned ? Color.accentColor : .secondary)
                                Text(person)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Edit Actions

    private func startEditing() {
        editableAssignments = [:]
        if let result = viewModel.assignmentResult {
            for assignment in result.assignments {
                editableAssignments[assignment.itemName] = Set(assignment.assignedTo)
            }
        }
        isEditing = true
    }

    private func toggleAssignment(item: String, person: String) {
        if editableAssignments[item] == nil {
            editableAssignments[item] = []
        }
        if editableAssignments[item]!.contains(person) {
            editableAssignments[item]!.remove(person)
        } else {
            editableAssignments[item]!.insert(person)
        }
    }

    private func applyEdits() {
        guard var result = viewModel.assignmentResult else { return }

        result.assignments = viewModel.editableItems.map { item in
            let people = editableAssignments[item.name] ?? []
            return ItemAssignment(itemName: item.name, assignedTo: Array(people).sorted())
        }

        viewModel.assignmentResult = result
        viewModel.calculateFinalSplits()
        isEditing = false
    }
}
