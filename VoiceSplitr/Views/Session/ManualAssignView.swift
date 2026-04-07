import SwiftUI

struct ManualAssignView: View {
    @Bindable var viewModel: NewSessionViewModel
    @State private var editModel = EditAssignmentModel()
    @State private var newPersonName = ""
    @State private var showingAssignInfo = false

    var body: some View {
        List {
            Section("People") {
                ForEach(editModel.people) { person in
                    HStack {
                        Text(person.name)
                        Spacer()
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
                Section {
                    Text("Tap each person who shared an item. Unassigned items are split equally among everyone.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } header: {
                    HStack {
                        Text("Assign Items")
                        Spacer()
                        Button {
                            showingAssignInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.subheadline)
                                .foregroundStyle(Color.brandBlue)
                        }
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
        .sheet(isPresented: $showingAssignInfo) {
            AssignInfoSheet()
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
        guard !name.isEmpty, !editModel.people.contains(where: { $0.name == name }) else { return }
        editModel.addPerson(name)
        newPersonName = ""
    }

    private func calculateAndContinue() {
        let assignments = editModel.toAssignments()
        let people = editModel.people.map { $0.name }
        viewModel.assignmentResult = BillAssignmentResult(assignments: assignments, people: people)
        viewModel.calculateFinalSplits()
        viewModel.currentStep = .results
    }
}

struct AssignInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    InfoSection(
                        icon: "checkmark.circle.fill",
                        iconColor: .brandBlue,
                        title: "Assigning Items",
                        description: "Tap each person who ordered or shared an item. You can assign an item to multiple people — the cost will be split equally among them."
                    )

                    InfoSection(
                        icon: "person.2.circle.fill",
                        iconColor: .brandIndigo,
                        title: "Unassigned Items",
                        description: "Any items left unassigned will be split equally among everyone. This is useful for shared appetizers, drinks, or sides that the whole table enjoyed."
                    )

                    InfoSection(
                        icon: "percent",
                        iconColor: .brandBlueLight,
                        title: "Tax & Tip",
                        description: "Tax and tip are split proportionally based on each person's share of the subtotal. If you ordered 40% of the food, you pay 40% of the tax and tip."
                    )

                    InfoSection(
                        icon: "pencil.circle.fill",
                        iconColor: .orange,
                        title: "Editing After",
                        description: "You can always edit assignments on the results page by tapping \"Edit\" — no need to get everything perfect the first time."
                    )
                }
                .padding()
            }
            .navigationTitle("How Assigning Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
