import SwiftUI

struct SplitResultsView: View {
    @Bindable var viewModel: NewSessionViewModel

    var body: some View {
        List {
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
    }
}
