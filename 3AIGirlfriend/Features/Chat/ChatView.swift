import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var appState: AppState
    @State private var draft = ""
    @State private var showProfile = false
    @State private var showSettings = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                    if !appState.isSubscribed {
                        freeCounterBar
                    }

                    messagesList

                    if !appState.isSubscribed || !MockReplyGenerator.suggestions.isEmpty {
                        suggestionsBar
                    }

                    inputBar
                }

                if appState.showPostCloseBanner {
                    VStack {
                        Spacer()
                        PostCloseOfferBanner(
                            onTap: { appState.openPostCloseOffer() },
                            onDismiss: { appState.dismissPostCloseBanner() }
                        )
                        .padding(.horizontal, 12)
                        .padding(.bottom, 96)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.86), value: appState.showPostCloseBanner)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showProfile) {
                CompanionProfileView()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            if !appState.isSubscribed {
                Button {
                    appState.presentPaywall(context: .general)
                } label: {
                    Text(String(localized: "common.upgrade"))
                        .font(AppFonts.caption(12))
                        .foregroundStyle(AppColors.primaryDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.bubbleAI)
                        .clipShape(Capsule())
                }
            } else {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Spacer()

            VStack(spacing: 2) {
                Text(appState.selectedCompanion.name)
                    .font(AppFonts.bodySemibold(17))
                    .foregroundStyle(AppColors.textPrimary)
                HStack(spacing: 5) {
                    Circle()
                        .fill(AppColors.online)
                        .frame(width: 7, height: 7)
                    Text(String(localized: "common.online"))
                        .font(AppFonts.tiny(11))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Spacer()

            Button {
                showProfile = true
            } label: {
                CompanionAvatarView(companion: appState.selectedCompanion, size: 40)
            }

            if !appState.isSubscribed {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 28, height: 40)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.background)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppColors.border).frame(height: 1)
        }
    }

    private var freeCounterBar: some View {
        Text(appState.messagesLeft == 1
             ? String(localized: "chat.messages_left_one")
             : String(format: String(localized: "chat.messages_left_many"), locale: .current, appState.messagesLeft))
            .font(AppFonts.caption(13))
            .foregroundStyle(AppColors.danger)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(AppColors.danger.opacity(0.08))
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(appState.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }

                    if appState.isTyping {
                        TypingIndicatorView()
                            .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .clearScrollBackground()
            .onChange(of: appState.messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: appState.isTyping) { _, _ in
                scrollToBottom(proxy)
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) {
                if appState.isTyping {
                    proxy.scrollTo("typing", anchor: .bottom)
                } else if let last = appState.messages.last?.id {
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
        }
    }

    private var suggestionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MockReplyGenerator.suggestions, id: \.self) { suggestion in
                    Button {
                        draft = ""
                        appState.applySuggestion(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(AppFonts.caption(13))
                            .foregroundStyle(AppColors.primaryDark)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(AppColors.bubbleAI)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            Button {
                appState.requestLockedFeature(.photos)
            } label: {
                lockedIcon("photo")
            }

            TextField(String(localized: "chat.message_placeholder"), text: $draft, axis: .vertical)
                .font(AppFonts.body(16))
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppColors.softGray)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .focused($inputFocused)

            Button {
                let text = draft
                draft = ""
                appState.sendUserMessage(text)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? AppColors.textTertiary
                        : AppColors.primary
                    )
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppColors.background)
        .overlay(alignment: .top) {
            Rectangle().fill(AppColors.border).frame(height: 1)
        }
    }

    private func lockedIcon(_ systemName: String) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 34, height: 34)

            if !appState.isSubscribed {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(3)
                    .background(AppColors.primary)
                    .clipShape(Circle())
                    .offset(x: 4, y: -2)
            }
        }
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.sender == .user { Spacer(minLength: 48) }

            Text(message.text)
                .font(AppFonts.body(15))
                .foregroundStyle(message.sender == .user ? .white : AppColors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if message.sender == .user {
                            AppColors.primary
                        } else {
                            AppColors.bubbleAI
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(alignment: .leading) {
                    if message.sender == .ai {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppColors.primary.opacity(0.55))
                            .frame(width: 3)
                            .padding(.vertical, 8)
                            .padding(.leading, 2)
                    }
                }

            if message.sender == .ai { Spacer(minLength: 48) }
        }
    }
}

struct TypingIndicatorView: View {
    var body: some View {
        HStack {
            TimelineView(.periodic(from: .now, by: 0.35)) { context in
                let phase = Int(context.date.timeIntervalSinceReferenceDate / 0.35) % 3
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(AppColors.primary.opacity(phase == index ? 1 : 0.35))
                            .frame(width: 7, height: 7)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.bubbleAI)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer()
        }
    }
}
