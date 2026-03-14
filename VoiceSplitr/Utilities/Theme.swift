import SwiftUI

// MARK: - Brand Colors

extension Color {
    /// Primary brand blue - vibrant sky blue
    static let brandBlue = Color(red: 0.20, green: 0.56, blue: 0.98)

    /// Secondary brand color - deeper blue
    static let brandIndigo = Color(red: 0.24, green: 0.35, blue: 0.90)

    /// Lighter variant for dark mode accents
    static let brandBlueLight = Color(red: 0.40, green: 0.68, blue: 1.0)

    /// Soft background tint (15% opacity brand blue)
    static let brandBlueSoft = Color.brandBlue.opacity(0.15)

    /// Light blue-tinted background for the app
    static let themeBg = Color("AppBackground")

    /// Card surface color
    static let themeCard = Color("CardBackground")
}

// MARK: - Brand Gradients

extension LinearGradient {
    /// Primary brand gradient: blue to indigo
    static let brandGradient = LinearGradient(
        colors: [Color.brandBlue, Color.brandIndigo],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Horizontal brand gradient
    static let brandGradientHorizontal = LinearGradient(
        colors: [Color.brandBlue, Color.brandIndigo],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Subtle brand gradient (slightly transparent)
    static let brandGradientSubtle = LinearGradient(
        colors: [Color.brandBlue.opacity(0.8), Color.brandIndigo.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                isEnabled
                    ? LinearGradient.brandGradient
                    : LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundStyle(Color.brandBlue)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.brandBlueSoft)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Gradient Icon

struct GradientIcon: View {
    let systemName: String
    var size: CGFloat = 60

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size))
            .foregroundStyle(LinearGradient.brandGradient)
            .padding(size * 0.4)
            .background(Color.brandBlueSoft)
            .clipShape(Circle())
    }
}

// MARK: - Gradient Card Modifier

struct GradientCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.themeCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.brandBlue.opacity(0.12), radius: 8, y: 4)
    }
}

extension View {
    func gradientCard() -> some View {
        modifier(GradientCardStyle())
    }
}
