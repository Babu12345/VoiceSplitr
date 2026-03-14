import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SettingsViewModel()
    @State private var newAPIKey = ""
    @State private var showingKeyInput = false

    var body: some View {
        NavigationStack {
            List {
                #if DEBUG
                Section {
                    if viewModel.hasStoredKey {
                        HStack {
                            Text("API Key")
                            Spacer()
                            Text(viewModel.apiKey)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Button("Update API Key") {
                            newAPIKey = ""
                            showingKeyInput = true
                        }

                        Button("Remove API Key", role: .destructive) {
                            viewModel.deleteAPIKey()
                        }
                    } else {
                        Button("Add Claude API Key") {
                            newAPIKey = ""
                            showingKeyInput = true
                        }
                    }

                    if viewModel.hasStoredKey {
                        Button {
                            Task { await viewModel.testConnection() }
                        } label: {
                            if viewModel.isTesting {
                                HStack {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                    Text("Testing...")
                                }
                            } else {
                                Text("Test Connection")
                            }
                        }
                        .disabled(viewModel.isTesting)
                    }

                    if let result = viewModel.testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(result.contains("successful") ? .green : .red)
                    }
                } header: {
                    Text("Claude API")
                } footer: {
                    Text("Get your API key from console.anthropic.com")
                }
                #endif

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Enter API Key", isPresented: $showingKeyInput) {
                TextField("sk-ant-...", text: $newAPIKey)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Save") {
                    viewModel.saveAPIKey(newAPIKey)
                    newAPIKey = ""
                }
                Button("Cancel", role: .cancel) {
                    newAPIKey = ""
                }
            } message: {
                Text("Enter your Claude API key. It will be stored securely in the Keychain.")
            }
        }
    }
}
