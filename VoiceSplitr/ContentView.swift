import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SplitSession.createdAt, order: .reverse) private var sessions: [SplitSession]
    @State private var showingNewSession = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()

                if sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionListView
                }
            }
            .scrollContentBackground(.hidden)
            .toolbarBackground(Color.themeBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
        .tint(.brandBlue)
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            GradientIcon(systemName: "receipt", size: 60)

            Text("No Splits Yet")
                .font(.title2)
                .fontWeight(.bold)

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
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 40)
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
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandBlue)

                Text("\(session.people.count) people")
                    .font(.caption)
                    .foregroundStyle(Color.brandBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.brandBlueSoft)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

struct SessionDetailView: View {
    @Bindable var session: SplitSession

    var body: some View {
        ZStack {
            Color.themeBg.ignoresSafeArea()

            List {
                if let imageData = session.receiptImageData,
                   let uiImage = UIImage(data: imageData) {
                    Section {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .frame(maxWidth: .infinity)
                            .listRowInsets(EdgeInsets())
                    } header: {
                        Text("Receipt")
                    }
                }

                Section("Title") {
                    TextField("Session name", text: $session.title)
                }

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
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(person.name)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("$\(String(format: "%.2f", person.shareAmount))")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.brandBlue)
                            }

                            ForEach(person.assignedItems) { item in
                                HStack {
                                    Text(item.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    let share = item.totalPrice / Double(max(item.assignedTo.count, 1))
                                    Text("$\(String(format: "%.2f", share))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
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
                            .foregroundStyle(Color.brandBlue)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .toolbarBackground(Color.themeBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationTitle(session.title)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SplitSession.self, inMemory: true)
}
