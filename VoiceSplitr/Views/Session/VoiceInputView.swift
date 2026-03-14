import SwiftUI

struct VoiceInputView: View {
    @Bindable var viewModel: NewSessionViewModel

    var body: some View {
        List {
            Section {
                Text("Each person should describe what they ordered. Tap the microphone to start recording.")
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
                        Text("$\(String(format: "%.2f", item.price * Double(item.quantity)))")
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                }
            }

            Section("Speaker Name") {
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
                    ForEach(Array(viewModel.transcripts.enumerated()), id: \.offset) { index, transcript in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(transcript.speaker)
                                .font(.headline)
                            Text(transcript.text)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        for offset in offsets {
                            viewModel.removeTranscript(at: offset)
                        }
                    }
                }
            }

            if !viewModel.transcripts.isEmpty && !viewModel.speechService.isRecording {
                Section {
                    Button {
                        Task { await viewModel.processAssignments() }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isProcessing {
                                ProgressView()
                                    .padding(.horizontal, 20)
                            } else {
                                Label("Process & Split Bill", systemImage: "wand.and.stars")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isProcessing)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
        }
        .task {
            await viewModel.speechService.requestAuthorization()
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
