import SwiftUI

struct ReceiptReviewView: View {
    @Bindable var viewModel: NewSessionViewModel
    @State private var showingFullReceipt = false

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
                        .onTapGesture {
                            showingFullReceipt = true
                        }
                } header: {
                    Text("Receipt")
                } footer: {
                    Text("Tap to zoom")
                        .font(.caption2)
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

                    HStack {
                        ForEach([15, 18, 20, 25], id: \.self) { percent in
                            Button("\(percent)%") {
                                viewModel.tipPercentage = Double(percent)
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
                    viewModel.currentStep = .voiceInput
                } label: {
                    Label("Continue to Voice Input", systemImage: "mic.fill")
                }
                .buttonStyle(.primary)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }
        }
        .fullScreenCover(isPresented: $showingFullReceipt) {
            if let image = viewModel.receiptImage {
                ZoomableReceiptView(image: image)
            }
        }
    }
}

struct ZoomableReceiptView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                scale = lastScale * value.magnification
                            }
                            .onEnded { value in
                                lastScale = scale
                                if scale < 1.0 {
                                    withAnimation {
                                        scale = 1.0
                                        lastScale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.0 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation {
                            if scale > 1.0 {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 3.0
                                lastScale = 3.0
                            }
                        }
                    }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
