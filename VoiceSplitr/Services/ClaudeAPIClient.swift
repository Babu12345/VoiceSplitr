import Foundation

enum ClaudeAPIError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case httpError(Int, String)
    case decodingError(String)
    case modelUnavailable
    case authenticationFailed
    case rateLimited
    case serviceUnavailable

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
        case .modelUnavailable:
            return "Receipt scanning needs an update. Please install the latest version of VoiceSplitr from the App Store."
        case .authenticationFailed:
            return "Could not authenticate with the scanning service. If you're using your own API key, please check it in Settings."
        case .rateLimited:
            return "Too many requests right now. Please wait a moment and try again."
        case .serviceUnavailable:
            return "The scanning service is temporarily busy. Please try again in a few minutes."
        }
    }
}

actor ClaudeAPIClient {
    private let directURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let apiVersion = "2023-06-01"
    private let model = "claude-sonnet-4-6"
    private let keychainKey = "claude_api_key"

    // MARK: - Proxy Configuration
    // Set your Railway proxy URL here once deployed (e.g. "https://voicesplit-proxy-production.up.railway.app")
    private static let proxyBaseURL: String? = "https://web-production-96a21.up.railway.app"
    private static let appSecret: String? = "2461a022f58a6fe483ae1ec40aa86fb15d5057ad5e1c78390fea0e09b3d37232"

    private var useProxy: Bool {
        Self.proxyBaseURL != nil
    }

    private var baseURL: URL {
        if let proxy = Self.proxyBaseURL {
            return URL(string: "\(proxy)/v1/messages")!
        }
        return directURL
    }

    private var apiKey: String? {
        if useProxy { return nil }
        return KeychainService.load(key: keychainKey)
    }

    func sendMessage(system: String, userContent: [MessageContent]) async throws -> String {
        if !useProxy {
            guard apiKey != nil else {
                throw ClaudeAPIError.noAPIKey
            }
        }

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")

        if let apiKey = apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        }
        if let secret = Self.appSecret {
            request.setValue(secret, forHTTPHeaderField: "x-app-secret")
        }

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
            throw Self.mapError(statusCode: httpResponse.statusCode, data: data)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstBlock = contentArray.first,
              let text = firstBlock["text"] as? String else {
            throw ClaudeAPIError.invalidResponse
        }

        return text
    }

    /// Maps a non-200 API response to a user-presentable error.
    /// 400/413 stay as .httpError — callers pattern-match those codes to retry with a smaller image.
    private static func mapError(statusCode: Int, data: Data) -> ClaudeAPIError {
        // API error bodies look like: {"type":"error","error":{"type":"...","message":"..."}}
        var apiMessage = "Unknown error"
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            apiMessage = message
        } else if let raw = String(data: data, encoding: .utf8), !raw.isEmpty {
            apiMessage = raw
        }

        switch statusCode {
        case 404:
            return .modelUnavailable
        case 401, 403:
            return .authenticationFailed
        case 429:
            return .rateLimited
        case 500...:
            return .serviceUnavailable
        default:
            return .httpError(statusCode, apiMessage)
        }
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
