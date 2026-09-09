import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var step: Step = .character
    @State private var selectedID: String = CompanionCatalog.all[0].id
    @State private var name: String = ""
    @FocusState private var nameFocused: Bool

    private var freeCompanionID: String { CompanionCatalog.all[0].id }

    private var selectedCompanion: Companion {
        CompanionCatalog.companion(id: selectedID)
    }

    enum Step {
        case character
        case name
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                progressHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                if step == .character {
                    characterStep
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else {
                    nameStep
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.28), value: step)
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(step == .character
                 ? String(localized: "onboarding.step_1")
                 : String(localized: "onboarding.step_2"))
                .font(AppFonts.caption(13))
                .foregroundStyle(AppColors.textTertiary)

            Text(step == .character
                 ? String(localized: "onboarding.choose_companion_title")
                 : String(localized: "onboarding.name_title"))
                .font(AppFonts.title(28))
                .foregroundStyle(AppColors.textPrimary)

            Text(step == .character
                 ? String(localized: "onboarding.choose_companion_subtitle")
                 : String(localized: "onboarding.name_subtitle"))
                .font(AppFonts.body(15))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var characterStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ],
                        spacing: 10
                    ) {
                        ForEach(CompanionCatalog.all) { companion in
                            characterCard(companion)
                        }
                    }

                    Text(String(localized: "onboarding.unlock_all_premium"))
                        .font(AppFonts.caption(12))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .clearScrollBackground()

            PrimaryButton(
                title: String(
                    format: String(localized: "onboarding.continue_with"),
                    locale: .current,
                    selectedCompanion.name
                )
            ) {
                appState.prepareNotificationsAfterCompanionSelection()
                withAnimation { step = .name }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    nameFocused = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func characterCard(_ companion: Companion) -> some View {
        let isFree = companion.id == freeCompanionID
        let selected = selectedID == companion.id

        return Button {
            if isFree {
                selectedID = companion.id
            } else {
                appState.presentPaywall(context: .featureCharacters)
            }
        } label: {
            ZStack {
                CompanionPortraitView(companion: companion, cornerRadius: 14)
                    .frame(height: 148)
                    .blur(radius: isFree ? 0 : 8)
                    .clipped()

                if !isFree {
                    Color.black.opacity(0.22)

                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                            .padding(8)
                            .background(AppColors.white.opacity(0.92))
                            .clipShape(Circle())

                        Text(String(localized: "onboarding.premium_badge"))
                            .font(AppFonts.tiny(10))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected && isFree ? AppColors.primary : Color.clear, lineWidth: 2.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var nameStep: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                CompanionAvatarView(companion: selectedCompanion, size: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedCompanion.name)
                        .font(AppFonts.bodySemibold(16))
                    Text(String(localized: "onboarding.excited_to_meet"))
                        .font(AppFonts.caption(13))
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            TextField(String(localized: "onboarding.name_placeholder"), text: $name)
                .font(AppFonts.body(18))
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(AppColors.softGray)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColors.primary.opacity(nameFocused ? 1 : 0), lineWidth: 2)
                )
                .focused($nameFocused)
                .textInputAutocapitalization(.words)
                .submitLabel(.continue)
                .onSubmit { finish() }
                .padding(.horizontal, 20)

            Spacer()

            HStack {
                Button {
                    withAnimation { step = .character }
                } label: {
                    Text(String(localized: "common.back"))
                        .font(AppFonts.bodySemibold(16))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(height: 56)
                        .padding(.horizontal, 8)
                }

                PrimaryButton(
                    title: String(localized: "common.continue"),
                    enabled: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    finish()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func finish() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Free onboarding always keeps the unlocked companion
        selectedID = freeCompanionID
        nameFocused = false
        appState.completeOnboarding(companionID: freeCompanionID, name: trimmed)
    }
}
