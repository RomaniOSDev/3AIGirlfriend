import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showDeleteChatConfirm = false
    @State private var showDeleteAccountConfirm = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    section(title: String(localized: "settings.subscription")) {
                        settingsRow(
                            icon: "crown.fill",
                            title: appState.isSubscribed
                                ? String(localized: "settings.pro_plan")
                                : String(localized: "settings.free_plan"),
                            subtitle: appState.isSubscribed
                                ? String(localized: "settings.pro_subtitle")
                                : String(localized: "settings.free_subtitle")
                        ) {
                            if !appState.isSubscribed {
                                appState.presentPaywall(context: .general)
                            }
                        }

                        if appState.isSubscribed {
                            settingsRow(
                                icon: "arrow.up.forward.app",
                                title: String(localized: "settings.manage_subscription"),
                                subtitle: String(localized: "settings.manage_subscription_subtitle")
                            ) {
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    openURL(url)
                                }
                            }
                        }

                        settingsRow(
                            icon: "arrow.clockwise",
                            title: String(localized: "common.restore"),
                            subtitle: String(localized: "settings.restore_subtitle")
                        ) {
                            Task { await appState.restorePurchases() }
                        }
                    }

                    section(title: String(localized: "settings.notifications")) {
                        toggleRow(
                            icon: "bell.badge.fill",
                            title: String(localized: "settings.chat_reminders"),
                            isOn: $appState.chatRemindersEnabled
                        )
                    }

                    section(title: String(localized: "settings.privacy")) {
                        settingsRow(
                            icon: "trash",
                            title: String(localized: "settings.delete_chat"),
                            subtitle: String(localized: "settings.delete_chat_subtitle")
                        ) {
                            showDeleteChatConfirm = true
                        }
                        settingsRow(
                            icon: "person.crop.circle.badge.minus",
                            title: String(localized: "settings.delete_account"),
                            subtitle: String(localized: "settings.delete_account_subtitle")
                        ) {
                            showDeleteAccountConfirm = true
                        }
                    }

                    section(title: String(localized: "settings.about")) {
                        settingsRow(
                            icon: "info.circle",
                            title: String(localized: "settings.version"),
                            subtitle: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                        )
                        linkRow(
                            title: String(localized: "settings.terms_of_use"),
                            url: URL(string: "https://docs.google.com/document/d/1ikHqibybPUBRtaDCUrN1HeHsb9ZEXNaBUgVabG6e-Oo/edit?usp=sharing")!
                        )
                        linkRow(
                            title: String(localized: "settings.privacy_policy"),
                            url: URL(string: "https://docs.google.com/document/d/1CU06qaNCYPq5lRN0Ofq-O563BHPS5q_0oD0KiCUic_4/edit?usp=sharing")!
                        )
                        linkRow(
                            title: String(localized: "settings.support"),
                            url: URL(string: "bakhrom86157@icloud.com")!
                        )
                    }

                    #if DEBUG
                    section(title: String(localized: "settings.debug")) {
                        settingsRow(
                            icon: "arrow.counterclockwise",
                            title: String(localized: "settings.reset_onboarding"),
                            subtitle: String(localized: "settings.reset_onboarding_subtitle")
                        ) {
                            appState.resetForDebug()
                            dismiss()
                        }
                        settingsRow(
                            icon: "checkmark.seal.fill",
                            title: String(localized: "settings.toggle_subscription"),
                            subtitle: appState.isSubscribed
                                ? String(localized: "settings.currently_pro")
                                : String(localized: "settings.currently_free")
                        ) {
                            if appState.isSubscribed {
                                appState.isSubscribed = false
                            } else {
                                appState.activateSubscription()
                            }
                        }
                    }
                    #endif
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .clearScrollBackground()
        }
        .navigationTitle(String(localized: "settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            String(localized: "settings.delete_chat_confirm"),
            isPresented: $showDeleteChatConfirm,
            titleVisibility: .visible
        ) {
            Button(String(localized: "common.delete"), role: .destructive) {
                let name = appState.userName.isEmpty
                    ? String(localized: "chat.fallback_name")
                    : appState.userName
                appState.messages = [
                    ChatMessage(
                        sender: .ai,
                        text: String(format: String(localized: "chat.fresh_start"), locale: .current, name)
                    )
                ]
            }
            Button(String(localized: "common.cancel"), role: .cancel) {}
        }
        .confirmationDialog(
            String(localized: "settings.delete_account_confirm"),
            isPresented: $showDeleteAccountConfirm,
            titleVisibility: .visible
        ) {
            Button(String(localized: "common.delete"), role: .destructive) {
                appState.resetForDebug()
                dismiss()
            }
            Button(String(localized: "common.cancel"), role: .cancel) {}
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(AppFonts.tiny(11))
                .foregroundStyle(AppColors.textTertiary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(AppColors.softGray.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func settingsRow(icon: String, title: String, subtitle: String, action: (() -> Void)? = nil) -> some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.bodySemibold(15))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(AppFonts.caption(12))
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppColors.primary)
                .frame(width: 24)
            Text(title)
                .font(AppFonts.bodySemibold(15))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColors.primary)
        }
        .padding(14)
    }

    private func linkRow(title: String, url: URL) -> some View {
        Link(destination: url) {
            HStack {
                Text(title)
                    .font(AppFonts.bodySemibold(15))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(14)
        }
    }
}
