import SwiftUI

struct VoiceInputView: View {
    @Bindable var viewModel: NewSessionViewModel

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    Text("Each person should describe what they ordered. Tap the microphone to start recording.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Section("Speaker Name") {
                    TextField("e.g., John", text: $viewModel.currentSpeakerName)
                }

                Section("Live Transcript") {
                    if viewModel.speechService.currentTranscript.isEmpty {
                        Text(viewModel.speechService.isRecording ? "Listening..." : "Tap the microphone to start")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        Text(viewModel.speechService.currentTranscript)
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
            }

            Divider()

            // Bottom controls
            VStack(spacing: 16) {
                RecordingButton(isRecording: viewModel.speechService.isRecording) {
                    toggleRecording()
                }

                if !viewModel.speechService.isRecording && !viewModel.speechService.currentTranscript.isEmpty {
                    HStack(spacing: 16) {
                        Button("Discard") {
                            viewModel.speechService.currentTranscript = ""
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)

                        Button("Save Transcript") {
                            viewModel.addTranscript()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if !viewModel.transcripts.isEmpty && !viewModel.speechService.isRecording {
                    Button {
                        Task { await viewModel.processAssignments() }
                    } label: {
                        if viewModel.isProcessing {
                            ProgressView()
                                .padding(.horizontal, 20)
                        } else {
                            Label("Process & Split Bill", systemImage: "wand.and.stars")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isProcessing)
                }
            }
            .padding()
            .background(.bar)
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
