import SwiftUI

struct VoiceInputView: View {
    @Bindable var viewModel: NewSessionViewModel
    @State private var showingConsentSheet = false

    var body: some View {
        List {
            Section {
                Text("Each person should describe what they ordered, or one person can describe everything — just make sure to clearly name each person. Tap the microphone to start recording.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Items on the Bill") {
                ForEach(viewModel.editableItems) { item in
                    HStack {
                        Text(item.name)
                        if item.quantity > 1 {
                            Text("x\(item.quantity)")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("$\(String(format: "%.2f", item.price))")
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                }
            }

            Section("Speaker Name (optional)") {
                TextField("e.g., John", text: $viewModel.currentSpeakerName)
            }

            Section {
                VStack(spacing: 16) {
                    RecordingButton(isRecording: viewModel.speechService.isRecording) {
                        toggleRecording()
                    }

                    if viewModel.speechService.currentTranscript.isEmpty {
                        Text(viewModel.speechService.isRecording ? "Listening..." : "Tap the microphone to start")
                            .foregroundStyle(.secondary)
                            .italic()
                            .font(.callout)
                    } else {
                        Text(viewModel.speechService.currentTranscript)
                            .font(.body)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } header: {
                Text("Live Transcript")
            }

            if !viewModel.speechService.isRecording && !viewModel.speechService.currentTranscript.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        Button("Discard") {
                            viewModel.speechService.currentTranscript = ""
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)

                        Button("Save Transcript") {
                            viewModel.addTranscript()
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }

            if !viewModel.transcripts.isEmpty {
                Section("Recorded Transcripts") {
                    ForEach($viewModel.transcripts) { $transcript in
                        VStack(alignment: .leading, spacing: 6) {
                            TextField("Speaker name", text: $transcript.speaker)
                                .font(.headline)
                            TextField("Transcript", text: $transcript.text, axis: .vertical)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        viewModel.transcripts.remove(atOffsets: offsets)
                    }
                }
            }

            if !viewModel.transcripts.isEmpty && !viewModel.speechService.isRecording {
                Section {
                    Button {
                        if DataSharingConsent.hasConsented {
                            Task { await viewModel.processAssignments() }
                        } else {
                            showingConsentSheet = true
                        }
                    } label: {
                        if viewModel.isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label("Process & Split Bill", systemImage: "wand.and.stars")
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(viewModel.isProcessing)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
        }
        .task {
            await viewModel.speechService.requestAuthorization()
        }
        .sheet(isPresented: $showingConsentSheet) {
            DataSharingConsentView(
                onAgree: {
                    DataSharingConsent.setConsent(true)
                    showingConsentSheet = false
                    Task { await viewModel.processAssignments() }
                },
                onCancel: {
                    showingConsentSheet = false
                }
            )
        }
    }

    private func toggleRecording() {
        if viewModel.speechService.isRecording {
            viewModel.speechService.stopRecording()
        } else {
            do {
                try viewModel.speechService.startRecording()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}
