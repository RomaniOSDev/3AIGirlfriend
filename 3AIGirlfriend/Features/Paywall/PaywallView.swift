import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @State private var selectedPlan: SubscriptionPlan = .weekly
    @State private var hardCloseUnlocked = false

    private var isHardLimit: Bool {
        appState.paywallContext == .messageLimit
    }

    private var isPostClose: Bool {
        appState.paywallContext == .postCloseOffer || appState.postCloseOfferActive
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    heroImage

                    VStack(alignment: .leading, spacing: 16) {
                        titleBlock
                        socialProof
                        benefits
                        planCards
                        ctaBlock
                        trialTimeline
                        comparisonTable
                        footerLinks
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 36)
                }
            }
            .clearScrollBackground()

            if appState.showExitIntent {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {}

                ExitIntentDrawer(
                    monthlyTitle: store.exitMonthlyTitle(),
                    annualTitle: store.exitAnnualTitle(),
                    onMonthly: { Task { await purchase(.monthly) } },
                    onAnnual: { Task { await purchase(.annual) } },
                    onContinueFree: {
                        appState.continueWithFreeMessages()
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.9), value: appState.showExitIntent)
        .task {
            await store.refresh()
        }
        .onAppear {
            selectedPlan = (appState.preferAnnualSelection || isPostClose) ? .annual : .weekly
            if isHardLimit {
                hardCloseUnlocked = false
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    hardCloseUnlocked = true
                }
            } else {
                hardCloseUnlocked = true
            }
        }
    }

    private var heroImage: some View {
        ZStack(alignment: .topLeading) {
            CompanionPortraitView(companion: appState.selectedCompanion, cornerRadius: 0)
                .frame(height: 280)
                .overlay(
                    LinearGradient(
                        colors: [.clear, .clear, AppColors.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Button {
                guard hardCloseUnlocked else { return }
                appState.dismissPaywall(allowExitIntent: true)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(hardCloseUnlocked ? Color.white.opacity(0.9) : Color.white.opacity(0.3))
                    .padding(10)
                    .background(.black.opacity(0.28))
                    .clipShape(Circle())
            }
            .disabled(!hardCloseUnlocked)
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    private var titleBlock: some View {
        Text(isPostClose
             ? String(localized: "paywall.special_offer_title")
             : String(localized: "paywall.waiting_title"))
            .font(AppFonts.title(28))
            .foregroundStyle(AppColors.textPrimary)
    }

    private var socialProof: some View {
        HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .foregroundStyle(AppColors.star)
                    .font(.system(size: 12))
            }
            Text(String(localized: "paywall.reviews"))
                .font(AppFonts.caption(12))
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            benefitRow(icon: "bubble.left.and.bubble.right.fill", text: String(localized: "paywall.benefit_chat"))
            benefitRow(icon: "photo.fill", text: String(localized: "paywall.benefit_photos"))
            benefitRow(icon: "sparkles", text: String(localized: "paywall.benefit_characters"))
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .frame(width: 22)
            Text(text)
                .font(AppFonts.body(15))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
        }
    }

    private var planCards: some View {
        VStack(spacing: 10) {
            ForEach(SubscriptionPlan.allCases) { plan in
                planCard(plan)
            }
        }
    }

    private func planCard(_ plan: SubscriptionPlan) -> some View {
        let selected = selectedPlan == plan
        return Button {
            selectedPlan = plan
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(AppFonts.bodySemibold(16))
                            .foregroundStyle(AppColors.textPrimary)
                        if let badge = plan.badge {
                            Text(badge)
                                .font(AppFonts.tiny(10))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColors.primary)
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 6) {
                        Text(displayPrice(for: plan))
                            .font(AppFonts.bodySemibold(16))
                            .foregroundStyle(AppColors.primary)
                        if let was = strikethroughPrice(for: plan), !(isPostClose && plan == .annual) {
                            Text(was)
                                .font(AppFonts.caption(12))
                                .strikethrough()
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }

                    Text(secondaryPrice(for: plan))
                        .font(AppFonts.caption(12))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer(minLength: 8)

                radio(selected: selected)
            }
            .padding(14)
            .background(selected ? AppColors.planSelectedFill : AppColors.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? AppColors.primary : AppColors.border, lineWidth: selected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func displayPrice(for plan: SubscriptionPlan) -> String {
        if let live = store.primaryPriceLabel(for: plan) {
            return live
        }
        return plan.priceLabel
    }

    private func secondaryPrice(for plan: SubscriptionPlan) -> String {
        store.secondaryPriceLabel(for: plan) ?? plan.secondaryPrice
    }

    private func strikethroughPrice(for plan: SubscriptionPlan) -> String? {
        store.strikethroughPrice(for: plan) ?? plan.strikethroughPrice
    }

    private func radio(selected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(selected ? AppColors.primary : AppColors.border, lineWidth: 2)
                .frame(width: 22, height: 22)
            if selected {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 12, height: 12)
            }
        }
    }

    private var ctaBlock: some View {
        VStack(spacing: 8) {
            PrimaryButton(
                title: String(localized: "paywall.cta_start"),
                isLoading: store.isPurchasing
            ) {
                Task { await purchase(selectedPlan) }
            }

            if let error = store.lastErrorMessage, !error.isEmpty {
                Text(error)
                    .font(AppFonts.caption(12))
                    .foregroundStyle(AppColors.danger)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Text(ctaSubtitle)
                .font(AppFonts.caption(12))
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func purchase(_ plan: SubscriptionPlan) async {
        selectedPlan = plan
        await appState.purchase(plan: plan)
    }

    private var ctaSubtitle: String {
        store.ctaSubtitle(for: selectedPlan, isOffer: isPostClose)
    }

    private var trialTimeline: some View {
        HStack(alignment: .top, spacing: 0) {
            timelineItem(
                title: String(localized: "paywall.trial_today"),
                subtitle: String(localized: "paywall.trial_free"),
                filled: true
            )
            timelineLine()
            timelineItem(
                title: String(localized: "paywall.trial_day2"),
                subtitle: String(localized: "paywall.trial_reminder"),
                filled: false
            )
            timelineLine()
            timelineItem(
                title: String(localized: "paywall.trial_day3"),
                subtitle: String(localized: "paywall.trial_charge"),
                filled: false
            )
        }
        .padding(.vertical, 8)
    }

    private func timelineItem(title: String, subtitle: String, filled: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(AppColors.primary, lineWidth: 2)
                    .frame(width: 14, height: 14)
                if filled {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 14, height: 14)
                }
            }
            Text(title)
                .font(AppFonts.bodySemibold(13))
                .foregroundStyle(AppColors.textPrimary)
            Text(subtitle)
                .font(AppFonts.caption(12))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func timelineLine() -> some View {
        Rectangle()
            .fill(AppColors.primary.opacity(0.35))
            .frame(height: 2)
            .padding(.top, 6)
            .frame(maxWidth: .infinity)
    }

    private var comparisonTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "paywall.free_vs_premium"))
                .font(AppFonts.headline(18))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.bottom, 12)

            comparisonHeader
            comparisonRow(
                String(localized: "paywall.row_messages"),
                free: String(localized: "paywall.free_messages"),
                pro: String(localized: "paywall.pro_messages"),
                freeIsLimited: true
            )
            comparisonRow(
                String(localized: "paywall.row_characters"),
                free: String(localized: "paywall.free_characters"),
                pro: String(localized: "paywall.pro_characters"),
                freeIsLimited: true
            )
            comparisonRow(
                String(localized: "paywall.row_photos"),
                free: String(localized: "paywall.dash"),
                pro: String(localized: "paywall.check"),
                freeIsLimited: false
            )
            comparisonRow(
                String(localized: "paywall.row_customization"),
                free: String(localized: "paywall.dash"),
                pro: String(localized: "paywall.check"),
                freeIsLimited: false
            )
        }
    }

    private var comparisonHeader: some View {
        HStack {
            Text(String(localized: "paywall.col_feature"))
                .font(AppFonts.caption(12))
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(String(localized: "paywall.col_free"))
                .font(AppFonts.caption(12))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 88, alignment: .center)
            Text(String(localized: "paywall.col_premium"))
                .font(AppFonts.caption(12))
                .foregroundStyle(AppColors.primary)
                .frame(width: 88, alignment: .center)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppColors.border).frame(height: 1)
        }
    }

    private func comparisonRow(
        _ feature: String,
        free: String,
        pro: String,
        freeIsLimited: Bool
    ) -> some View {
        HStack {
            Text(feature)
                .font(AppFonts.body(14))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(free)
                .font(AppFonts.bodySemibold(14))
                .foregroundStyle(freeIsLimited ? AppColors.danger : AppColors.textTertiary)
                .frame(width: 88, alignment: .center)
            Text(pro)
                .font(AppFonts.bodySemibold(14))
                .foregroundStyle(AppColors.primary)
                .frame(width: 88, alignment: .center)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppColors.border).frame(height: 1)
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 20) {
            footerLink(String(localized: "common.terms"), action: nil)
            footerLink(String(localized: "common.restore")) {
                Task { await appState.restorePurchases() }
            }
            footerLink(String(localized: "common.privacy"), action: nil)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private func footerLink(_ title: String, action: (() -> Void)?) -> some View {
        Button(title) {
            action?()
        }
        .font(AppFonts.caption(12))
        .foregroundStyle(AppColors.textTertiary)
    }
}
