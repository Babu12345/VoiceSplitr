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

        let transcriptsList = Self.formatTranscripts(transcripts)

        let systemPrompt = """
        You are a bill splitter assistant. Given a list of receipt items and voice transcripts \
        describing what people ordered, match each item to the person(s) who ordered it.

        How to read transcripts:
        - Each transcript is prefixed with a speaker label in brackets, e.g. [Babu]: or [Speaker 1]:.
        - Labels starting with "Speaker " (e.g. [Speaker 1], [Speaker 2]) are routing tags for an \
        unnamed person — they are NOT real names.
        - First-person pronouns ("I", "me", "my", "mine", "I'm", "I've", "I'll", "I'd", and any \
        equivalent in other languages) inside a transcript refer to the bracket label of that \
        transcript.

        When to include the bracket label in the people array:
        - If the bracket label is a real name (e.g. [Babu]) AND the transcript either uses \
        first-person pronouns OR mentions that name in the text, include it.
        - If the bracket label is a routing tag like [Speaker 1], include "Speaker 1" in people \
        ONLY when the transcript uses first-person pronouns indicating that speaker actually \
        ordered something. If the transcript is purely third-person narration (e.g. \
        "Babu and Joe got the fries, Max got the pasta"), DO NOT include "Speaker 1" in people \
        and DO NOT assign any items to it — treat the label as if it weren't there.
        - NEVER invent names that are not in a bracket label or spoken in a transcript.

        Assignment rules:
        - A single transcript may describe what MULTIPLE people ordered. Extract all names mentioned.
        - If someone says two people "shared" or "split" an item, assign that item to both of them.
        - Phrases like "the rest", "everything else", "the other items" mean ALL remaining items \
        that were NOT explicitly assigned to someone else. Only assign those unmentioned items.
        - Be precise: if someone says "I got the burger", ONLY assign the burger to them, not other items.
        - Do NOT assign all items to one person unless they explicitly said they ordered everything.
        - If an item is not mentioned by anyone, leave assigned_to as an empty array.
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

    /// Renders transcripts as bracket-prefixed quoted lines for the prompt.
    /// A nil speaker falls back to a bare "Speaker" tag (the view model normally
    /// supplies "Speaker N", so this is just a safety net).
    static func formatTranscripts(
        _ transcripts: [(speaker: String?, text: String)]
    ) -> String {
        transcripts.map { t in
            let speaker = t.speaker ?? "Speaker"
            return "[\(speaker)]: \"\(t.text)\""
        }.joined(separator: "\n")
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
