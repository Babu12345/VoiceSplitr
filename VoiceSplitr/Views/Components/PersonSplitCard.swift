import SwiftUI

struct PersonSplitCard: View {
    let split: PersonSplit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(split.name)
                    .font(.headline)
                Spacer()
                Text("$\(String(format: "%.2f", split.total))")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            ForEach(split.items, id: \.name) { item in
                HStack {
                    Text(item.name)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", item.amount))")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("Items: $\(String(format: "%.2f", split.itemsSubtotal))")
                    Text("Tax: $\(String(format: "%.2f", split.taxShare))")
                    Text("Tip: $\(String(format: "%.2f", split.tipShare))")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}
