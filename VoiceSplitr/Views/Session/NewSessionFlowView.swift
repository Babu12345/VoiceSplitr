import SwiftUI

struct NewSessionFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = NewSessionViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Step indicator
                    stepIndicator
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Divider()
                        .padding(.top, 8)

                    // Step content
                    Group {
                        switch viewModel.currentStep {
                        case .captureReceipt:
                            ReceiptCaptureView(viewModel: viewModel)
                        case .reviewItems:
                            ReceiptReviewView(viewModel: viewModel)
                        case .voiceInput:
                            VoiceInputView(viewModel: viewModel)
                        case .results:
                            SplitResultsView(viewModel: viewModel)
                        case .share:
                            ShareResultsView(viewModel: viewModel)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .toolbarBackground(Color.themeBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle(viewModel.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.currentStep == .captureReceipt {
                        Button("Cancel") { dismiss() }
                    } else {
                        Button("Back") { goBack() }
                    }
                }

                if viewModel.currentStep == .share {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            _ = viewModel.saveSession(to: modelContext)
                            dismiss()
                        }
                    }
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 4) {
            ForEach(SessionStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= viewModel.currentStep.rawValue ? LinearGradient.brandGradientHorizontal : LinearGradient(colors: [Color.secondary.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 4)
            }
        }
    }

    private func goBack() {
        let currentRaw = viewModel.currentStep.rawValue
        if currentRaw > 0, let previous = SessionStep(rawValue: currentRaw - 1) {
            viewModel.currentStep = previous
        }
    }
}
