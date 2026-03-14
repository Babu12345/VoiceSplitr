import SwiftUI

struct ShareResultsView: View {
    @Bindable var viewModel: NewSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bill Split Summary")
                        .font(.title2)
                        .fontWeight(.bold)

                    Divider()

                    ForEach(viewModel.splits) { split in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(split.name)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("$\(String(format: "%.2f", split.total))")
                                    .fontWeight(.bold)
                            }

                            ForEach(split.items, id: \.name) { item in
                                HStack {
                                    Text("  \(item.name)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("$\(String(format: "%.2f", item.amount))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            HStack(spacing: 12) {
                                Text("Tax: $\(String(format: "%.2f", split.taxShare))")
                                Text("Tip: $\(String(format: "%.2f", split.tipShare))")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)

                        if split.id != viewModel.splits.last?.id {
                            Divider()
                        }
                    }

                    Divider()

                    HStack {
                        Text("Grand Total")
                            .font(.headline)
                        Spacer()
                        Text("$\(String(format: "%.2f", viewModel.splits.reduce(0) { $0 + $1.total }))")
                            .font(.headline)
                    }
                }
                .padding()
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                .padding(.horizontal)

                // Share button
                ShareLink(item: viewModel.shareText) {
                    Label("Share Split", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)

                // Save & close button
                Button {
                    viewModel.saveSession(to: modelContext)
                    dismiss()
                } label: {
                    Label("Save & Close", systemImage: "checkmark.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, 40)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}
