//
//  TranscriptLabelingTests.swift
//  VoiceSplitrTests
//

import Testing
@testable import VoiceSplitr

struct TranscriptLabelingTests {

    // MARK: - buildTranscriptData

    @Test func untypedTranscriptGetsSpeakerOneLabel() {
        let entries = [TranscriptEntry(speaker: "", text: "I got the fries")]
        let result = NewSessionViewModel.buildTranscriptData(from: entries)

        #expect(result.count == 1)
        #expect(result[0].speaker == "Speaker 1")
        #expect(result[0].text == "I got the fries")
    }

    @Test func typedNameWinsOverSpeakerLabel() {
        let entries = [TranscriptEntry(speaker: "Babu", text: "I got the fries")]
        let result = NewSessionViewModel.buildTranscriptData(from: entries)

        #expect(result[0].speaker == "Babu")
    }

    @Test func typedNameIsTrimmed() {
        let entries = [TranscriptEntry(speaker: "  Babu  ", text: "fries")]
        let result = NewSessionViewModel.buildTranscriptData(from: entries)

        #expect(result[0].speaker == "Babu")
    }

    @Test func whitespaceOnlySpeakerTreatedAsEmpty() {
        let entries = [TranscriptEntry(speaker: "   ", text: "fries")]
        let result = NewSessionViewModel.buildTranscriptData(from: entries)

        #expect(result[0].speaker == "Speaker 1")
    }

    @Test func numberingOnlyAdvancesForUntypedEntries() {
        let entries = [
            TranscriptEntry(speaker: "",     text: "first untyped"),
            TranscriptEntry(speaker: "Babu", text: "typed in middle"),
            TranscriptEntry(speaker: "",     text: "second untyped"),
            TranscriptEntry(speaker: "Joe",  text: "another typed"),
            TranscriptEntry(speaker: "",     text: "third untyped"),
        ]
        let result = NewSessionViewModel.buildTranscriptData(from: entries)

        #expect(result.map { $0.speaker } == [
            "Speaker 1",
            "Babu",
            "Speaker 2",
            "Joe",
            "Speaker 3",
        ])
    }

    @Test func textIsPreservedExactly() {
        let entries = [TranscriptEntry(speaker: "", text: "I'll take the soup, Joe got bread")]
        let result = NewSessionViewModel.buildTranscriptData(from: entries)

        #expect(result[0].text == "I'll take the soup, Joe got bread")
    }

    @Test func emptyInputProducesEmptyOutput() {
        let result = NewSessionViewModel.buildTranscriptData(from: [])
        #expect(result.isEmpty)
    }

    // MARK: - formatTranscripts

    @Test func formatsBracketLabelAndQuotes() {
        let formatted = BillAssignmentService.formatTranscripts([
            (speaker: "Babu", text: "I got the fries")
        ])
        #expect(formatted == "[Babu]: \"I got the fries\"")
    }

    @Test func formatsSpeakerNumberLabel() {
        let formatted = BillAssignmentService.formatTranscripts([
            (speaker: "Speaker 1", text: "Babu and Joe split the pizza")
        ])
        #expect(formatted == "[Speaker 1]: \"Babu and Joe split the pizza\"")
    }

    @Test func nilSpeakerFallsBackToSpeakerTag() {
        let formatted = BillAssignmentService.formatTranscripts([
            (speaker: nil, text: "anonymous line")
        ])
        #expect(formatted == "[Speaker]: \"anonymous line\"")
    }

    @Test func joinsMultipleTranscriptsWithNewlines() {
        let formatted = BillAssignmentService.formatTranscripts([
            (speaker: "Speaker 1", text: "I got fries"),
            (speaker: "Babu",      text: "Joe got pasta"),
        ])
        #expect(formatted == """
        [Speaker 1]: "I got fries"
        [Babu]: "Joe got pasta"
        """)
    }

    @Test func emptyListProducesEmptyString() {
        let formatted = BillAssignmentService.formatTranscripts([])
        #expect(formatted.isEmpty)
    }

    // MARK: - End-to-end pipeline (view model → service formatter)

    @Test func pipelineUntypedFirstPersonGetsSpeakerOneInPrompt() {
        let entries = [TranscriptEntry(speaker: "", text: "I got the fries")]
        let data = NewSessionViewModel.buildTranscriptData(from: entries)
        let formatted = BillAssignmentService.formatTranscripts(data)

        #expect(formatted == "[Speaker 1]: \"I got the fries\"")
    }

    @Test func pipelineMixedTypedAndUntyped() {
        let entries = [
            TranscriptEntry(speaker: "",     text: "Babu and Joe got fries"),
            TranscriptEntry(speaker: "Max",  text: "I got the pasta"),
            TranscriptEntry(speaker: "",     text: "I had the soup"),
        ]
        let data = NewSessionViewModel.buildTranscriptData(from: entries)
        let formatted = BillAssignmentService.formatTranscripts(data)

        #expect(formatted == """
        [Speaker 1]: "Babu and Joe got fries"
        [Max]: "I got the pasta"
        [Speaker 2]: "I had the soup"
        """)
    }
}
