import Foundation

@Observable
class SettingsViewModel {
    var apiKey: String = ""
    var isTesting = false
    var testResult: String?
    var hasStoredKey: Bool = false

    private let keychainKey = "claude_api_key"
    private let client = ClaudeAPIClient()

    init() {
        loadKeyStatus()
    }

    func loadKeyStatus() {
        if let key = KeychainService.load(key: keychainKey) {
            hasStoredKey = true
            // Show masked key
            if key.count > 8 {
                apiKey = String(key.prefix(4)) + String(repeating: "*", count: key.count - 8) + String(key.suffix(4))
            } else {
                apiKey = String(repeating: "*", count: key.count)
            }
        } else {
            hasStoredKey = false
            apiKey = ""
        }
    }

    func saveAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let success = KeychainService.save(key: keychainKey, value: trimmed)
        if success {
            hasStoredKey = true
            loadKeyStatus()
        }
    }

    func deleteAPIKey() {
        _ = KeychainService.delete(key: keychainKey)
        hasStoredKey = false
        apiKey = ""
        testResult = nil
    }

    func testConnection() async {
        isTesting = true
        testResult = nil

        do {
            let success = try await client.testConnection()
            await MainActor.run {
                self.testResult = success ? "Connection successful!" : "Connection failed."
                self.isTesting = false
            }
        } catch {
            await MainActor.run {
                self.testResult = "Error: \(error.localizedDescription)"
                self.isTesting = false
            }
        }
    }
}
