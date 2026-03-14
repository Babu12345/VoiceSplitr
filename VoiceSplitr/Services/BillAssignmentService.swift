import Foundation

@Observable
class BillAssignmentService {
    private let client = ClaudeAPIClient()

    var isProcessing = false
    var errorMessage: String?

    func assignItems(
        lineItems: [(name: String, price: Double)],
        transcripts: [(speaker: String?, text: String)]
    ) async throws -> BillAssignmentResult {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        let itemsList = lineItems.map { "- \($0.name): $\(String(format: "%.2f", $0.price))" }
            .joined(separator: "\n")

        let transcriptsList = transcripts.enumerated().map { index, t in
            let speaker = t.speaker ?? "Person \(index + 1)"
            return "[\(speaker)]: \"\(t.text)\""
        }.joined(separator: "\n")

        let systemPrompt = """
        You are a bill splitter assistant. Given a list of receipt items and voice transcripts \
        from different people describing what they ordered, match each item to the person(s) who ordered it.

        If an item is shared, assign it to all people who mentioned it.
        If an item is not mentioned by anyone, leave assigned_to as an empty array.
        Identify people by the speaker names provided in the transcripts.

        Return ONLY valid JSON matching this exact schema (no markdown, no explanation):
        {
          "assignments": [
            {"item_name": "Item name", "assigned_to": ["Person 1", "Person 2"]}
          ],
          "people": ["Person 1", "Person 2"]
        }
        """

        let userMessage = """
        Receipt items:
        \(itemsList)

        Voice transcripts:
        \(transcriptsList)

        Match each item to the person(s) who ordered it.
        """

        let response = try await client.sendMessage(
            system: systemPrompt,
            userContent: [.text(userMessage)]
        )

        return try parseJSON(from: response)
    }

    private func parseJSON(from response: String) throws -> BillAssignmentResult {
        var jsonString = response.trimmingCharacters(in: .whitespacesAndNewlines)

        if let jsonStart = jsonString.range(of: "{"),
           let jsonEnd = jsonString.range(of: "}", options: .backwards) {
            jsonString = String(jsonString[jsonStart.lowerBound..<jsonEnd.upperBound])
        }

        guard let data = jsonString.data(using: .utf8) else {
            throw ClaudeAPIError.decodingError("Could not convert response to data")
        }

        do {
            return try JSONDecoder().decode(BillAssignmentResult.self, from: data)
        } catch {
            throw ClaudeAPIError.decodingError(error.localizedDescription)
        }
    }
}
