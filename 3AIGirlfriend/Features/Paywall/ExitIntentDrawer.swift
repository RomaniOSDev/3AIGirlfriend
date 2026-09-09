import SwiftUI

struct ExitIntentDrawer: View {
    var monthlyTitle: String
    var annualTitle: String
    var onMonthly: () -> Void
    var onAnnual: () -> Void
    var onContinueFree: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(AppColors.border)
                .frame(width: 40, height: 4)
                .padding(.top, 8)

            Text(String(localized: "exit.title"))
                .font(AppFonts.headline(20))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(String(localized: "exit.subtitle"))
                .font(AppFonts.body(14))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button(action: onMonthly) {
                    Text(monthlyTitle)
                        .primaryButtonStyle()
                }
                .buttonStyle(.plain)

                Button(action: onAnnual) {
                    Text(annualTitle)
                        .font(AppFonts.bodySemibold(16))
                        .foregroundStyle(AppColors.primaryDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.bubbleAI)
                        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Text(String(localized: "exit.coffee"))
                .font(AppFonts.caption(12))
                .foregroundStyle(AppColors.textTertiary)

            Button(String(localized: "exit.continue_free"), action: onContinueFree)
                .font(AppFonts.caption(13))
                .foregroundStyle(AppColors.textSecondary)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.white)
                .shadow(color: .black.opacity(0.12), radius: 20, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
