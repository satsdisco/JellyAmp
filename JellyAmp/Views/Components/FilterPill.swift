import SwiftUI

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.jellyAmpCaption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.jellyAmpAccent : Color.white.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.jellyAmpAccent.opacity(isSelected ? 0.8 : 0.3), lineWidth: 1)
                )
        }
    }
}

