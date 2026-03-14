import Foundation
import SwiftData

enum SessionStatus: String, Codable {
    case draft
    case parsed
    case voiceRecorded
    case split
    case shared
}

@Model
final class SplitSession {
    var id: UUID
    var title: String
    var createdAt: Date
    var receiptImageData: Data?
    var subtotal: Double
    var taxAmount: Double
    var tipAmount: Double
    var tipPercentage: Double?
    var statusRaw: String

    @Relationship(deleteRule: .cascade, inverse: \LineItem.session)
    var lineItems: [LineItem]

    @Relationship(deleteRule: .cascade, inverse: \Person.session)
    var people: [Person]

    @Relationship(deleteRule: .cascade, inverse: \VoiceTranscript.session)
    var voiceTranscripts: [VoiceTranscript]

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var totalAmount: Double {
        subtotal + taxAmount + tipAmount
    }

    init(
        title: String = "",
        receiptImageData: Data? = nil,
        subtotal: Double = 0,
        taxAmount: Double = 0,
        tipAmount: Double = 0,
        tipPercentage: Double? = nil,
        status: SessionStatus = .draft
    ) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.receiptImageData = receiptImageData
        self.subtotal = subtotal
        self.taxAmount = taxAmount
        self.tipAmount = tipAmount
        self.tipPercentage = tipPercentage
        self.statusRaw = status.rawValue
        self.lineItems = []
        self.people = []
        self.voiceTranscripts = []
    }
}
