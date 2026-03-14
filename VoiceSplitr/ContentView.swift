import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SplitSession.createdAt, order: .reverse) private var sessions: [SplitSession]
    @State private var showingNewSession = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionListView
                }
            }
            .navigationTitle("VoiceSplitr")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewSession = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingNewSession) {
                NewSessionFlowView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "receipt")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Splits Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Take a photo of a receipt and split the bill with friends using your voice.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showingNewSession = true
            } label: {
                Label("New Split", systemImage: "camera.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
    }

    private var sessionListView: some View {
        List {
            ForEach(sessions) { session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    SessionRowView(session: session)
                }
            }
            .onDelete(perform: deleteSessions)
        }
    }

    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(sessions[index])
            }
        }
    }
}

struct SessionRowView: View {
    let session: SplitSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.title)
                .font(.headline)

            HStack {
                Text(session.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("$\(String(format: "%.2f", session.totalAmount))")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(session.people.count) people")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.fill.tertiary)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

struct SessionDetailView: View {
    let session: SplitSession

    var body: some View {
        List {
            Section("Items") {
                ForEach(session.lineItems) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text("$\(String(format: "%.2f", item.totalPrice))")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Split") {
                ForEach(session.people) { person in
                    HStack {
                        Text(person.name)
                            .fontWeight(.medium)
                        Spacer()
                        Text("$\(String(format: "%.2f", person.shareAmount))")
                            .fontWeight(.semibold)
                    }
                }
            }

            Section {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text("$\(String(format: "%.2f", session.subtotal))")
                }
                HStack {
                    Text("Tax")
                    Spacer()
                    Text("$\(String(format: "%.2f", session.taxAmount))")
                }
                HStack {
                    Text("Tip")
                    Spacer()
                    Text("$\(String(format: "%.2f", session.tipAmount))")
                }
                HStack {
                    Text("Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text("$\(String(format: "%.2f", session.totalAmount))")
                        .fontWeight(.bold)
                }
            }
        }
        .navigationTitle(session.title)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SplitSession.self, inMemory: true)
}
