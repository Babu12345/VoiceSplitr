import SwiftUI

struct RecordingButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var animationScale: CGFloat = 1.0

    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulsing background when recording
                if isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(animationScale)
                }

                Group {
                    if isRecording {
                        Circle()
                            .fill(Color.red)
                    } else {
                        Circle()
                            .fill(LinearGradient.brandGradient)
                    }
                }
                .frame(width: 64, height: 64)
                .shadow(color: (isRecording ? Color.red : Color.brandBlue).opacity(0.4), radius: 8, y: 4)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }
        }
        .onChange(of: isRecording) { _, recording in
            if recording {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    animationScale = 1.3
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    animationScale = 1.0
                }
            }
        }
    }
}
