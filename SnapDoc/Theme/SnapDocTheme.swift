import SwiftUI

enum SnapDocColor {
    static let background = Color(red: 0.027, green: 0.063, blue: 0.094)
    static let backgroundRaised = Color(red: 0.071, green: 0.122, blue: 0.176)
    static let card = Color(red: 0.102, green: 0.165, blue: 0.235)
    static let accent = Color(red: 0.298, green: 0.553, blue: 1.0)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.68)
    static let paper = Color(red: 0.965, green: 0.973, blue: 0.980)
    static let danger = Color(red: 1.0, green: 0.42, blue: 0.42)
}

struct SnapDocPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(SnapDocColor.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

struct SnapDocSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(SnapDocColor.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? SnapDocColor.accent : SnapDocColor.card, in: Capsule())
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? AccessibilityTraits.isSelected : [])
    }
}
