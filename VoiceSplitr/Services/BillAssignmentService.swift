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
        describing what people ordered, match each item to the person(s) who ordered it.

        Important rules:
        - A single transcript may describe what MULTIPLE people ordered. Extract all names mentioned.
        - "I", "me", or "my" refers to the speaker name shown in brackets before the transcript.
        - If someone says two people "shared" or "split" an item, assign that item to both of them.
        - Phrases like "the rest", "everything else", "the other items" mean ALL remaining items \
        that were NOT explicitly assigned to someone else. Only assign those unmentioned items.
        - Be precise: if someone says "I got the burger", ONLY assign the burger to them, not other items.
        - Each item should be assigned to exactly the people who ordered it. Do NOT assign all items to one person \
        unless they explicitly said they ordered everything.
        - If an item is not mentioned by anyone, leave assigned_to as an empty array.
        - The "people" array must include ALL people mentioned across all transcripts, including the speakers.
        - Use exact names as spoken (capitalize first letter).
        - item_name in the output must exactly match the item names from the receipt items list.

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
