import Foundation

enum ClaudeAPIError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case httpError(Int, String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No Claude API key configured. Please add your API key in Settings."
        case .invalidResponse:
            return "Invalid response from Claude API."
        case .httpError(let code, let message):
            return "API error (\(code)): \(message)"
        case .decodingError(let message):
            return "Failed to parse response: \(message)"
        }
    }
}

actor ClaudeAPIClient {
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let apiVersion = "2023-06-01"
    private let model = "claude-sonnet-4-20250514"
    private let keychainKey = "claude_api_key"

    private var apiKey: String? {
        if let userKey = KeychainService.load(key: keychainKey) {
            return userKey
        }
        return Self.bundledAPIKey
    }

    private static let bundledAPIKey: String? = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
              let key = dict["CLAUDE_API_KEY"],
              key != "YOUR_API_KEY_HERE" else {
            return nil
        }
        return key
    }()

    func sendMessage(system: String, userContent: [MessageContent]) async throws -> String {
        guard let apiKey = apiKey else {
            throw ClaudeAPIError.noAPIKey
        }

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")

        let content: [[String: Any]] = userContent.map { item in
            switch item {
            case .text(let text):
                return ["type": "text", "text": text]
            case .image(let data, let mediaType):
                return [
                    "type": "image",
                    "source": [
                        "type": "base64",
                        "media_type": mediaType,
                        "data": data.base64EncodedString()
                    ] as [String: Any]
                ]
            }
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "system": system,
            "messages": [
                ["role": "user", "content": content]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeAPIError.httpError(httpResponse.statusCode, errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstBlock = contentArray.first,
              let text = firstBlock["text"] as? String else {
            throw ClaudeAPIError.invalidResponse
        }

        return text
    }

    func testConnection() async throws -> Bool {
        let response = try await sendMessage(
            system: "Respond with exactly: OK",
            userContent: [.text("Test connection")]
        )
        return response.contains("OK")
    }
}

enum MessageContent {
    case text(String)
    case image(data: Data, mediaType: String)
}
