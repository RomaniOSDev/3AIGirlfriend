import SwiftUI

extension View {
    func clearScrollBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.clear)
    }

    func primaryButtonStyle(enabled: Bool = true) -> some View {
        self
            .font(AppFonts.bodySemibold(17))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppColors.primaryGradient)
                    .opacity(enabled ? 1 : 0.4)
            }
    }
}

struct PrimaryButton: View {
    let title: String
    var enabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .primaryButtonStyle(enabled: enabled && !isLoading)
        }
        .buttonStyle(.plain)
        .disabled(!enabled || isLoading)
    }
}
