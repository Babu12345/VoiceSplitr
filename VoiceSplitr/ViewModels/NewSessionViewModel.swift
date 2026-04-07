import Foundation
import SwiftUI
import SwiftData

struct TranscriptEntry: Identifiable {
    let id = UUID()
    var speaker: String
    var text: String
}

enum SessionStep: Int, CaseIterable {
    case captureReceipt
    case reviewItems
    case voiceInput
    case manualAssign
    case results
    case share

    var title: String {
        switch self {
        case .captureReceipt: return "Scan Receipt"
        case .reviewItems: return "Review Items"
        case .voiceInput: return "Voice Input"
        case .manualAssign: return "Assign Items"
        case .results: return "Split Results"
        case .share: return "Share"
        }
    }
}

@Observable
class NewSessionViewModel {
    // Navigation
    var currentStep: SessionStep = .captureReceipt

    // Receipt
    var receiptImage: UIImage?
    var parsedReceipt: ParsedReceipt?
    var editableItems: [ParsedLineItem] = []
    var subtotal: Double {
        editableItems.reduce(0) { $0 + $1.price }
    }
    var taxAmount: Double = 0
    var tipPercentage: Double = 18.0
    var tipAmount: Double {
        (subtotal * tipPercentage).rounded() / 100
    }
    var sessionTitle: String = ""

    // Voice
    var transcripts: [TranscriptEntry] = []
    var currentSpeakerName: String = ""

    // Results
    var splits: [PersonSplit] = []
    var assignmentResult: BillAssignmentResult?

    // State
    var isProcessing = false
    var errorMessage: String?
    var usedManualAssign = false

    // Services
    let receiptParser = ReceiptParsingService()
    let speechService = SpeechRecognitionService()
    let billAssigner = BillAssignmentService()

    // MARK: - Receipt Parsing

    func parseReceiptImage() async {
        guard let image = receiptImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "No image selected"
            return
        }

        isProcessing = true
        errorMessage = nil

        do {
            let parsed: ParsedReceipt
            do {
                parsed = try await receiptParser.parseReceipt(imageData: imageData)
            } catch let apiError as ClaudeAPIError {
                if case .httpError(let code, _) = apiError, code == 400 || code == 413 {
                    // Image too large — resize and retry
                    let resized = Self.resizeImage(image, maxDimension: 2048)
                    guard let smallerData = resized.jpegData(compressionQuality: 0.7) else {
                        throw apiError
                    }
                    parsed = try await receiptParser.parseReceipt(imageData: smallerData)
                } else {
                    throw apiError
                }
            }
            await MainActor.run {
                self.parsedReceipt = parsed
                self.editableItems = parsed.items
                self.taxAmount = parsed.tax ?? 0
                self.isProcessing = false
                self.currentStep = .reviewItems
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isProcessing = false
            }
        }
    }

    // MARK: - Item Editing

    func addItem() {
        editableItems.append(ParsedLineItem(name: "", price: 0, quantity: 1))
    }

    func removeItems(at offsets: IndexSet) {
        editableItems.remove(atOffsets: offsets)
        recalculateSubtotal()
    }

    func recalculateSubtotal() {
        // subtotal and tipAmount are now computed properties — no manual update needed
    }

    func updateTipAmount() {
        // tipAmount is now a computed property — no manual update needed
    }

    // MARK: - Voice Input

    func addTranscript() {
        let text = speechService.currentTranscript
        guard !text.isEmpty else { return }

        transcripts.append(TranscriptEntry(speaker: currentSpeakerName, text: text))
        currentSpeakerName = ""
        speechService.currentTranscript = ""
    }

    func removeTranscript(at index: Int) {
        guard index < transcripts.count else { return }
        transcripts.remove(at: index)
    }

    /// Builds the (speaker, text) payload sent to the bill assigner.
    /// - Typed names win and are whitespace-trimmed.
    /// - Untyped transcripts are tagged "Speaker N", numbered only across untyped entries.
    static func buildTranscriptData(
        from transcripts: [TranscriptEntry]
    ) -> [(speaker: String?, text: String)] {
        var counter = 0
        return transcripts.map { entry in
            let typed = entry.speaker.trimmingCharacters(in: .whitespaces)
            if !typed.isEmpty {
                return (speaker: typed, text: entry.text)
            }
            counter += 1
            return (speaker: "Speaker \(counter)", text: entry.text)
        }
    }

    // MARK: - Bill Assignment

    func processAssignments() async {
        isProcessing = true
        errorMessage = nil

        let items = editableItems.map { (name: $0.name, price: $0.price) }
        let transcriptData = Self.buildTranscriptData(from: transcripts)

        do {
            let result = try await billAssigner.assignItems(
                lineItems: items,
                transcripts: transcriptData
            )
            await MainActor.run {
                self.assignmentResult = result
                self.isProcessing = false
                self.calculateFinalSplits()
                self.currentStep = .results
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isProcessing = false
            }
        }
    }

    // MARK: - Split Calculation

    func calculateFinalSplits() {
        guard let result = assignmentResult else { return }

        // Create temporary LineItem and Person objects for the calculator
        // We use the assignment result to build the split
        var personMap: [String: (items: [(String, Double)], total: Double)] = [:]

        for person in result.people {
            personMap[person] = (items: [], total: 0)
        }

        for assignment in result.assignments {
            guard !assignment.assignedTo.isEmpty else { continue }

            let item = editableItems.first { $0.name == assignment.itemName }
            let price = item?.price ?? 0
            let share = price / Double(assignment.assignedTo.count)

            for person in assignment.assignedTo {
                if personMap[person] == nil {
                    personMap[person] = (items: [], total: 0)
                }
                personMap[person]?.items.append((assignment.itemName, share))
                personMap[person]?.total += share
            }
        }

        // Handle unassigned items
        let assignedItemNames = Set(result.assignments.filter { !$0.assignedTo.isEmpty }.map { $0.itemName })
        let unassignedItems = editableItems.filter { !assignedItemNames.contains($0.name) }

        if !unassignedItems.isEmpty && !personMap.isEmpty {
            let people = Array(personMap.keys)
            for item in unassignedItems {
                let share = item.price / Double(people.count)
                for person in people {
                    personMap[person]?.items.append((item.name, share))
                    personMap[person]?.total += share
                }
            }
        }

        // Remove people with no items assigned (e.g. speaker who only described others' orders)
        personMap = personMap.filter { !$0.value.items.isEmpty }

        let actualSubtotal = editableItems.reduce(0.0) { $0 + $1.price }

        let sortedPeople = personMap.sorted { $0.key < $1.key }
        var tempSplits: [PersonSplit] = []

        for (index, (name, data)) in sortedPeople.enumerated() {
            let itemsSubtotal = data.total
            let proportion = actualSubtotal > 0 ? itemsSubtotal / actualSubtotal : 0

            let taxShare: Double
            let tipShare: Double

            if index == sortedPeople.count - 1 {
                // Last person absorbs rounding remainder so totals match exactly
                taxShare = ((taxAmount - tempSplits.reduce(0.0) { $0 + $1.taxShare }) * 100).rounded() / 100
                tipShare = ((tipAmount - tempSplits.reduce(0.0) { $0 + $1.tipShare }) * 100).rounded() / 100
            } else {
                taxShare = (proportion * taxAmount * 100).rounded() / 100
                tipShare = (proportion * tipAmount * 100).rounded() / 100
            }

            let total = ((itemsSubtotal + taxShare + tipShare) * 100).rounded() / 100

            tempSplits.append(PersonSplit(
                id: UUID(),
                name: name,
                items: data.items.map { (name: $0.0, amount: $0.1) },
                itemsSubtotal: (itemsSubtotal * 100).rounded() / 100,
                taxShare: taxShare,
                tipShare: tipShare,
                total: total
            ))
        }

        splits = tempSplits
    }

    // MARK: - Save Session

    func saveSession(to context: ModelContext) -> SplitSession {
        let session = SplitSession(
            title: sessionTitle.isEmpty ? "Split \(Date().formatted(date: .abbreviated, time: .shortened))" : sessionTitle,
            receiptImageData: receiptImage?.jpegData(compressionQuality: 0.7),
            subtotal: subtotal,
            taxAmount: taxAmount,
            tipAmount: tipAmount,
            tipPercentage: tipPercentage,
            status: .split
        )

        context.insert(session)

        // Create people and line items
        var personModels: [String: Person] = [:]
        for split in splits {
            let person = Person(name: split.name)
            person.shareAmount = split.total
            person.session = session
            context.insert(person)
            personModels[split.name] = person
        }

        for editableItem in editableItems {
            let lineItem = LineItem(name: editableItem.name, price: editableItem.price, quantity: editableItem.quantity)
            lineItem.session = session
            context.insert(lineItem)

            // Assign people based on assignment result
            if let assignment = assignmentResult?.assignments.first(where: { $0.itemName == editableItem.name }) {
                for personName in assignment.assignedTo {
                    if let person = personModels[personName] {
                        lineItem.assignedTo.append(person)
                    }
                }
            }
        }

        // Save transcripts
        for transcript in transcripts {
            let vt = VoiceTranscript(rawText: transcript.text, speakerName: transcript.speaker)
            vt.session = session
            context.insert(vt)
        }

        return session
    }

    // MARK: - Share Text

    var shareText: String {
        var text = "Bill Split Summary\n"
        text += "==================\n\n"

        for split in splits {
            text += "\(split.name):\n"
            for item in split.items {
                text += "  - \(item.name): $\(String(format: "%.2f", item.amount))\n"
            }
            text += "  Subtotal: $\(String(format: "%.2f", split.itemsSubtotal))\n"
            text += "  Tax: $\(String(format: "%.2f", split.taxShare))\n"
            text += "  Tip: $\(String(format: "%.2f", split.tipShare))\n"
            text += "  TOTAL: $\(String(format: "%.2f", split.total))\n\n"
        }

        let grandTotal = splits.reduce(0) { $0 + $1.total }
        text += "Grand Total: $\(String(format: "%.2f", grandTotal))\n"
        text += "\nSplit with VoiceSplitr"

        return text
    }

    // MARK: - Image Resize

    static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
