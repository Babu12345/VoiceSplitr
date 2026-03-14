import Foundation
import SwiftData

@Model
final class VoiceTranscript {
    var id: UUID
    var speakerName: String?
    var rawText: String
    var recordedAt: Date

    var session: SplitSession?

    init(rawText: String, speakerName: String? = nil) {
        self.id = UUID()
        self.rawText = rawText
        self.speakerName = speakerName
        self.recordedAt = Date()
    }
}
