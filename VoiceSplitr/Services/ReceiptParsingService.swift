import Foundation

@Observable
class ReceiptParsingService {
    private let client = ClaudeAPIClient()

    var isProcessing = false
    var errorMessage: String?

    func parseReceipt(imageData: Data) async throws -> ParsedReceipt {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        let systemPrompt = """
        You are a receipt parser. Given an image of a receipt or bill, extract all line items \
        with their names, prices, and quantities. Also extract subtotal, tax, and total if visible.

        Return ONLY valid JSON matching this exact schema (no markdown, no explanation):
        {
          "items": [
            {"name": "Item name", "price": 12.99, "quantity": 1}
          ],
          "subtotal": 25.98,
          "tax": 2.34,
          "total": 28.32
        }

        Rules:
        - Prices should be numbers (not strings)
        - Quantity defaults to 1 if not specified
        - Use null for subtotal/tax/total if not visible on the receipt
        - Include all individual items, not category totals
        """

        let mediaType = detectMediaType(from: imageData)

        let response = try await client.sendMessage(
            system: systemPrompt,
            userContent: [.image(data: imageData, mediaType: mediaType)]
        )

        return try parseJSON(from: response)
    }

    private func parseJSON(from response: String) throws -> ParsedReceipt {
        // Extract JSON from response (handle potential markdown wrapping)
        var jsonString = response.trimmingCharacters(in: .whitespacesAndNewlines)

        if let jsonStart = jsonString.range(of: "{"),
           let jsonEnd = jsonString.range(of: "}", options: .backwards) {
            jsonString = String(jsonString[jsonStart.lowerBound..<jsonEnd.upperBound])
        }

        guard let data = jsonString.data(using: .utf8) else {
            throw ClaudeAPIError.decodingError("Could not convert response to data")
        }

        do {
            return try JSONDecoder().decode(ParsedReceipt.self, from: data)
        } catch {
            throw ClaudeAPIError.decodingError(error.localizedDescription)
        }
    }

    private func detectMediaType(from data: Data) -> String {
        guard data.count >= 4 else { return "image/jpeg" }

        let bytes = [UInt8](data.prefix(4))

        if bytes[0] == 0x89 && bytes[1] == 0x50 {
            return "image/png"
        } else if bytes[0] == 0xFF && bytes[1] == 0xD8 {
            return "image/jpeg"
        } else if bytes[0] == 0x47 && bytes[1] == 0x49 {
            return "image/gif"
        } else if bytes[0] == 0x52 && bytes[1] == 0x49 {
            return "image/webp"
        }

        return "image/jpeg"
    }
}
