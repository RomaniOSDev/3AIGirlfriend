import SwiftUI

struct FeaturePaywallSheet: View {
    @EnvironmentObject private var appState: AppState
    let kind: FeatureSheetKind

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(AppColors.border)
                .frame(width: 40, height: 4)
                .padding(.top, 8)

            visual
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(title)
                .font(AppFonts.headline(22))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(AppFonts.body(14))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            PrimaryButton(title: cta) {
                appState.showFeatureSheet = nil
                appState.presentPaywall(context: context)
            }

            Button(String(localized: "common.not_now")) {
                appState.showFeatureSheet = nil
            }
            .font(AppFonts.caption(13))
            .foregroundStyle(AppColors.textSecondary)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 20)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder
    private var visual: some View {
        switch kind {
        case .photos:
            ZStack {
                CompanionPortraitView(companion: appState.selectedCompanion, cornerRadius: 18)
                    .blur(radius: 10)
                Color.black.opacity(0.25)
                Image(systemName: "lock.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
        case .characters:
            HStack(spacing: 10) {
                ForEach(CompanionCatalog.all.prefix(3)) { companion in
                    CompanionPortraitView(companion: companion, cornerRadius: 14)
                        .blur(radius: 5)
                        .overlay(Color.black.opacity(0.2))
                        .overlay {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.white)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        case .edit:
            ZStack {
                CompanionPortraitView(companion: appState.selectedCompanion, cornerRadius: 18)
                Color.black.opacity(0.2)
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.white)
            }
        }
    }

    private var title: String {
        let name = appState.selectedCompanion.name
        switch kind {
        case .photos:
            return String(format: String(localized: "feature.photos_title"), locale: .current, name)
        case .characters:
            return String(localized: "feature.characters_title")
        case .edit:
            return String(format: String(localized: "feature.edit_title"), locale: .current, name)
        }
    }

    private var subtitle: String {
        switch kind {
        case .photos: return String(localized: "feature.photos_subtitle")
        case .characters: return String(localized: "feature.characters_subtitle")
        case .edit: return String(localized: "feature.edit_subtitle")
        }
    }

    private var cta: String {
        switch kind {
        case .photos: return String(localized: "feature.photos_cta")
        case .characters: return String(localized: "feature.characters_cta")
        case .edit: return String(localized: "feature.edit_cta")
        }
    }

    private var context: PaywallContext {
        switch kind {
        case .photos: return .featurePhotos
        case .characters: return .featureCharacters
        case .edit: return .editProfile
        }
    }
}

struct PostCloseOfferBanner: View {
    var onTap: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text("⏰")
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "banner.offer_title"))
                        .font(AppFonts.caption(12))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(String(localized: "banner.offer_subtitle"))
                        .font(AppFonts.bodySemibold(14))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(AppColors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: AppColors.primary.opacity(0.35), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}
