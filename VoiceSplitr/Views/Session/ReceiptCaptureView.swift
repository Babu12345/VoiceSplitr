import SwiftUI
import PhotosUI

struct ReceiptCaptureView: View {
    @Bindable var viewModel: NewSessionViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingConsentSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let image = viewModel.receiptImage {
                    // Show selected image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.brandBlue.opacity(0.15), radius: 8, y: 4)
                        .padding(.horizontal)

                    HStack(spacing: 16) {
                        Button("Retake") {
                            viewModel.receiptImage = nil
                            selectedPhotoItem = nil
                        }
                        .buttonStyle(.secondary)
                        .frame(width: 120)

                        Button {
                            if DataSharingConsent.hasConsented {
                                Task { await viewModel.parseReceiptImage() }
                            } else {
                                showingConsentSheet = true
                            }
                        } label: {
                            if viewModel.isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                            }
                        }
                        .buttonStyle(.primary)
                        .disabled(viewModel.isProcessing)
                    }
                    .padding(.horizontal, 24)
                } else {
                    // Image selection options
                    VStack(spacing: 32) {
                        GradientIcon(systemName: "doc.text.viewfinder", size: 60)
                            .padding(.top, 40)

                        Text("Take a photo of your receipt or select one from your library")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        VStack(spacing: 16) {
                            Button {
                                showingCamera = true
                            } label: {
                                Label("Take Photo", systemImage: "camera.fill")
                            }
                            .buttonStyle(.primary)

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Label("Choose from Library", systemImage: "photo.on.rectangle")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.brandBlue)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.brandBlueSoft)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                }
            }
            .padding(.vertical)
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.receiptImage = image
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(image: $viewModel.receiptImage)
        }
        .sheet(isPresented: $showingConsentSheet) {
            DataSharingConsentView(
                onAgree: {
                    DataSharingConsent.setConsent(true)
                    showingConsentSheet = false
                    Task { await viewModel.parseReceiptImage() }
                },
                onCancel: {
                    showingConsentSheet = false
                }
            )
        }
    }
}

// MARK: - Camera View (UIKit Wrapper)

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
