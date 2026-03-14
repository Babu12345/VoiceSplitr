import SwiftUI

struct ReceiptReviewView: View {
    @Bindable var viewModel: NewSessionViewModel

    var body: some View {
        List {
            if let image = viewModel.receiptImage {
                Section {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets())
                } header: {
                    Text("Receipt")
                }
            }

            Section("Receipt Items") {
                ForEach($viewModel.editableItems) { $item in
                    HStack {
                        VStack(alignment: .leading) {
                            TextField("Item name", text: $item.name)
                                .font(.body)

                            HStack {
                                Text("Qty:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("1", value: $item.quantity, format: .number)
                                    .frame(width: 40)
                                    .font(.caption)
                                    .keyboardType(.numberPad)
                            }
                        }

                        Spacer()

                        TextField("0.00", value: $item.price, format: .currency(code: "USD"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                    }
                }
                .onDelete(perform: viewModel.removeItems)

                Button {
                    viewModel.addItem()
                } label: {
                    Label("Add Item", systemImage: "plus.circle")
                        .foregroundStyle(Color.brandBlue)
                }
            }

            Section("Totals") {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text("$\(String(format: "%.2f", viewModel.subtotal))")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Tax")
                    Spacer()
                    TextField("0.00", value: $viewModel.taxAmount, format: .currency(code: "USD"))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        .frame(width: 100)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Tip (\(Int(viewModel.tipPercentage))%)")
                        Spacer()
                        Text("$\(String(format: "%.2f", viewModel.tipAmount))")
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $viewModel.tipPercentage, in: 0...30, step: 1) {
                        Text("Tip Percentage")
                    }
                    .onChange(of: viewModel.tipPercentage) { _, _ in
                        viewModel.updateTipAmount()
                    }

                    HStack {
                        ForEach([15, 18, 20, 25], id: \.self) { percent in
                            Button("\(percent)%") {
                                viewModel.tipPercentage = Double(percent)
                                viewModel.updateTipAmount()
                            }
                            .buttonStyle(.bordered)
                            .tint(viewModel.tipPercentage == Double(percent) ? Color.brandBlue : .secondary)
                        }
                    }
                }

                HStack {
                    Text("Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text("$\(String(format: "%.2f", viewModel.subtotal + viewModel.taxAmount + viewModel.tipAmount))")
                        .fontWeight(.bold)
                        .foregroundStyle(Color.brandBlue)
                }
            }

            Section {
                Button {
                    viewModel.recalculateSubtotal()
                    viewModel.currentStep = .voiceInput
                } label: {
                    Label("Continue to Voice Input", systemImage: "mic.fill")
                }
                .buttonStyle(.primary)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }
        }
        .onAppear {
            viewModel.recalculateSubtotal()
        }
    }
}
