import SwiftUI

struct DataSharingConsentView: View {
    let onAgree: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 50))
                            .foregroundStyle(.tint)

                        Text("Data Sharing Consent")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Your privacy matters to us")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)

                    Divider()

                    // What data is shared
                    VStack(alignment: .leading, spacing: 12) {
                        Label("What Data Will Be Shared", systemImage: "doc.text")
                            .font(.headline)
                            .foregroundStyle(.tint)

                        Text("When you process a bill split, the following information is sent to Anthropic:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            DataItem(icon: "camera", text: "Receipt images (for item extraction)")
                            DataItem(icon: "text.bubble", text: "Transcribed text from voice input")
                            DataItem(icon: "list.bullet", text: "Item names and prices from the receipt")
                        }
                        .padding(.leading, 8)
                    }

                    // What is NOT shared
                    VStack(alignment: .leading, spacing: 12) {
                        Label("What Is NOT Shared", systemImage: "lock.shield")
                            .font(.headline)
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 8) {
                            DataItem(icon: "mic.slash", text: "Raw voice recordings (processed on-device only)", color: .green)
                            DataItem(icon: "person.slash", text: "Personal identifying information", color: .green)
                            DataItem(icon: "creditcard.trianglebadge.exclamationmark", text: "Payment or financial account data", color: .green)
                            DataItem(icon: "clock.arrow.circlepath", text: "Your saved bill split history", color: .green)
                        }
                        .padding(.leading, 8)
                    }

                    // Who receives the data
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Who Receives Your Data", systemImage: "building.2")
                            .font(.headline)
                            .foregroundStyle(.tint)

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                                .foregroundStyle(.tint)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Anthropic")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text("Anthropic is an AI safety company that develops Claude, an AI assistant focused on being helpful, harmless, and honest.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Link(destination: URL(string: "https://www.anthropic.com/privacy")!) {
                                    HStack(spacing: 4) {
                                        Text("View Anthropic Privacy Policy")
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .font(.caption)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // How data is used
                    VStack(alignment: .leading, spacing: 12) {
                        Label("How Your Data Is Used", systemImage: "gearshape.2")
                            .font(.headline)
                            .foregroundStyle(.tint)

                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "Your data is used solely to parse receipts and match items to people")
                            BulletPoint(text: "We do not store your receipt images or transcripts on our servers")
                            BulletPoint(text: "Data is transmitted securely using encryption (HTTPS/TLS)")
                            BulletPoint(text: "Anthropic processes your data according to their privacy policy")
                        }
                    }

                    // Privacy policy link
                    VStack(alignment: .leading, spacing: 8) {
                        Text("For more details, see our")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Link(destination: URL(string: "https://babu12345.github.io/VoiceSplitr/privacy_policy/#ai-data-sharing")!) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Privacy Policy - AI Data Sharing")
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)
                }
                .padding(.horizontal)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button {
                        onAgree()
                    } label: {
                        Text("I Agree to Share Data with Anthropic")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views

private struct DataItem: View {
    let icon: String
    let text: String
    var color: Color = .primary

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color.opacity(0.8))
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(color == .primary ? .primary : color)
        }
    }
}

private struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\u{2022}")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Consent Manager

enum DataSharingConsent {
    private static let consentKey = "hasConsentedToDataSharing"

    static var hasConsented: Bool {
        UserDefaults.standard.bool(forKey: consentKey)
    }

    static func setConsent(_ consented: Bool) {
        UserDefaults.standard.set(consented, forKey: consentKey)
    }

    static func revokeConsent() {
        UserDefaults.standard.removeObject(forKey: consentKey)
    }
}

#Preview {
    DataSharingConsentView(
        onAgree: {},
        onCancel: {}
    )
}
