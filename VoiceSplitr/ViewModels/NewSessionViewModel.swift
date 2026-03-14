import Foundation
import SwiftUI
import SwiftData

enum SessionStep: Int, CaseIterable {
    case captureReceipt
    case reviewItems
    case voiceInput
    case results
    case share

    var title: String {
        switch self {
        case .captureReceipt: return "Scan Receipt"
        case .reviewItems: return "Review Items"
        case .voiceInput: return "Voice Input"
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
    var subtotal: Double = 0
    var taxAmount: Double = 0
    var tipPercentage: Double = 18.0
    var tipAmount: Double = 0
    var sessionTitle: String = ""

    // Voice
    var transcripts: [(speaker: String, text: String)] = []
    var currentSpeakerName: String = ""

    // Results
    var splits: [PersonSplit] = []
    var assignmentResult: BillAssignmentResult?

    // State
    var isProcessing = false
    var errorMessage: String?

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
            let parsed = try await receiptParser.parseReceipt(imageData: imageData)
            await MainActor.run {
                self.parsedReceipt = parsed
                self.editableItems = parsed.items
                self.subtotal = parsed.subtotal ?? parsed.items.reduce(0) { $0 + $1.price * Double($1.quantity) }
                self.taxAmount = parsed.tax ?? 0
                self.updateTipAmount()
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
        subtotal = editableItems.reduce(0) { $0 + $1.price * Double($1.quantity) }
        updateTipAmount()
    }

    func updateTipAmount() {
        tipAmount = (subtotal * tipPercentage / 100 * 100).rounded() / 100
    }

    // MARK: - Voice Input

    func addTranscript() {
        let text = speechService.currentTranscript
        guard !text.isEmpty else { return }

        let speaker = currentSpeakerName.isEmpty ? "Person \(transcripts.count + 1)" : currentSpeakerName
        transcripts.append((speaker: speaker, text: text))
        currentSpeakerName = ""
        speechService.currentTranscript = ""
    }

    func removeTranscript(at index: Int) {
        guard index < transcripts.count else { return }
        transcripts.remove(at: index)
    }

    // MARK: - Bill Assignment

    func processAssignments() async {
        isProcessing = true
        errorMessage = nil

        let items = editableItems.map { (name: $0.name, price: $0.price * Double($0.quantity)) }
        let transcriptData = transcripts.map { (speaker: Optional($0.speaker), text: $0.text) }

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
            let price = (item?.price ?? 0) * Double(item?.quantity ?? 1)
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
                let share = (item.price * Double(item.quantity)) / Double(people.count)
                for person in people {
                    personMap[person]?.items.append((item.name, share))
                    personMap[person]?.total += share
                }
            }
        }

        let actualSubtotal = editableItems.reduce(0.0) { $0 + $1.price * Double($1.quantity) }

        splits = personMap.map { name, data in
            let itemsSubtotal = data.total
            let proportion = actualSubtotal > 0 ? itemsSubtotal / actualSubtotal : 0
            let taxShare = (proportion * taxAmount * 100).rounded() / 100
            let tipShare = (proportion * tipAmount * 100).rounded() / 100
            let total = ((itemsSubtotal + taxShare + tipShare) * 100).rounded() / 100

            return PersonSplit(
                id: UUID(),
                name: name,
                items: data.items.map { (name: $0.0, amount: $0.1) },
                itemsSubtotal: (itemsSubtotal * 100).rounded() / 100,
                taxShare: taxShare,
                tipShare: tipShare,
                total: total
            )
        }.sorted { $0.name < $1.name }
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
}
