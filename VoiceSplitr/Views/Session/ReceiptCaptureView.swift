import SwiftUI
import PhotosUI

struct ReceiptCaptureView: View {
    @Bindable var viewModel: NewSessionViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false

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
                        .shadow(radius: 4)
                        .padding(.horizontal)

                    HStack(spacing: 16) {
                        Button("Retake") {
                            viewModel.receiptImage = nil
                            selectedPhotoItem = nil
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Task { await viewModel.parseReceiptImage() }
                        } label: {
                            if viewModel.isProcessing {
                                ProgressView()
                                    .padding(.horizontal, 20)
                            } else {
                                Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isProcessing)
                    }
                } else {
                    // Image selection options
                    VStack(spacing: 32) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 80))
                            .foregroundStyle(.secondary)
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
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.borderedProminent)

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Label("Choose from Library", systemImage: "photo.on.rectangle")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.bordered)
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
