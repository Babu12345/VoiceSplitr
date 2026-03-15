import SwiftUI

struct ManualAssignView: View {
    @Bindable var viewModel: NewSessionViewModel
    @State private var editModel = EditAssignmentModel()
    @State private var newPersonName = ""

    var body: some View {
        List {
            Section("People") {
                ForEach(editModel.people, id: \.self) { person in
                    HStack {
                        Text(person)
                        Spacer()
                        Button(role: .destructive) {
                            removePerson(person)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack {
                    TextField("Add person name", text: $newPersonName)
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

            if !editModel.people.isEmpty {
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

                        ForEach(editModel.people, id: \.self) { person in
                            Button {
                                editModel.toggle(item: editItem.name, person: person)
                            } label: {
                                HStack {
                                    Image(systemName: editModel.isAssigned(item: editItem.name, person: person) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(editModel.isAssigned(item: editItem.name, person: person) ? Color.brandBlue : .secondary)
                                    Text(person)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        calculateAndContinue()
                    } label: {
                        Label("Calculate Split", systemImage: "equal.circle")
                    }
                    .buttonStyle(.primary)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .disabled(editModel.people.isEmpty)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .onAppear {
            if editModel.people.isEmpty && editModel.items.isEmpty {
                editModel = EditAssignmentModel(
                    items: viewModel.editableItems,
                    people: viewModel.assignmentResult?.people.sorted() ?? [],
                    assignments: viewModel.assignmentResult?.assignments ?? []
                )
            }
        }
    }

    private func addPerson() {
        let name = newPersonName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !editModel.people.contains(name) else { return }
        editModel.people.append(name)
        for item in editModel.items {
            editModel.assignments[item.name]?[name] = false
        }
        newPersonName = ""
    }

    private func removePerson(_ person: String) {
        editModel.people.removeAll { $0 == person }
        for item in editModel.items {
            editModel.assignments[item.name]?[person] = nil
        }
    }

    private func calculateAndContinue() {
        let assignments = editModel.toAssignments()
        let people = editModel.people
        viewModel.assignmentResult = BillAssignmentResult(assignments: assignments, people: people)
        viewModel.calculateFinalSplits()
        viewModel.currentStep = .results
    }
}
