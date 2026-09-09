import SwiftUI

struct CompanionProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showCompanionPicker = false
    @State private var selectedPhotoIndex = 0

    private var photos: [String] {
        appState.selectedCompanion.photoAssetNames
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    hero
                    content
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
            .clearScrollBackground()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.black.opacity(0.35))
                        .clipShape(Circle())
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState.requestLockedFeature(.edit)
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.black.opacity(0.35))
                        .clipShape(Circle())
                }
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            CompanionPortraitView(
                companion: appState.selectedCompanion,
                cornerRadius: 0,
                photoIndex: selectedPhotoIndex
            )
            .frame(height: 360)
            .overlay(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("\(appState.selectedCompanion.name), \(appState.selectedCompanion.age)")
                    .font(AppFonts.title(30))
                    .foregroundStyle(.white)

                Text(appState.selectedCompanion.tag)
                    .font(AppFonts.caption(12))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.primary.opacity(0.9))
                    .clipShape(Capsule())

                Text(appState.selectedCompanion.bio)
                    .font(AppFonts.body(14))
                    .foregroundStyle(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 22) {
            aboutBlock
            connectionBlock
            changeCompanionRow

            Text(String(localized: "profile.photos"))
                .font(AppFonts.headline(18))
                .foregroundStyle(AppColors.textPrimary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(Array(photos.indices), id: \.self) { index in
                    galleryCell(index: index)
                }
            }
        }
        .sheet(isPresented: $showCompanionPicker) {
            CompanionPickerView()
                .environmentObject(appState)
        }
    }

    private var aboutBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "profile.about"))
                .font(AppFonts.headline(18))
                .foregroundStyle(AppColors.textPrimary)

            Text(appState.selectedCompanion.about)
                .font(AppFonts.body(15))
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.softGray)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var connectionBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(localized: "profile.your_connection"))
                    .font(AppFonts.headline(18))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text(appState.relationshipStage.title)
                    .font(AppFonts.caption(12))
                    .foregroundStyle(AppColors.primaryDark)
                    .multilineTextAlignment(.trailing)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.softGray)
                    Capsule()
                        .fill(AppColors.primaryGradient)
                        .frame(width: max(12, geo.size.width * appState.relationshipStage.progress))
                }
            }
            .frame(height: 8)

            HStack {
                ForEach(RelationshipStage.allCases, id: \.rawValue) { stage in
                    Text(stage.shortLabel)
                        .font(AppFonts.tiny(11))
                        .foregroundStyle(
                            stage == appState.relationshipStage
                            ? AppColors.primaryDark
                            : AppColors.textTertiary
                        )
                        .frame(
                            maxWidth: .infinity,
                            alignment: stage == .gettingToKnow
                            ? .leading
                            : (stage == .deeplyConnected ? .trailing : .center)
                        )
                }
            }
        }
    }

    private var changeCompanionRow: some View {
        Button {
            if appState.isSubscribed {
                showCompanionPicker = true
            } else {
                appState.requestLockedFeature(.characters)
            }
        } label: {
            HStack(spacing: 14) {
                overlappingAvatars

                VStack(alignment: .leading, spacing: 3) {
                    Text(String(localized: "profile.change_companion"))
                        .font(AppFonts.bodySemibold(16))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(
                        String(
                            format: String(localized: "profile.characters_available"),
                            locale: .current,
                            CompanionCatalog.all.count
                        )
                    )
                    .font(AppFonts.caption(12))
                    .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                if !appState.isSubscribed {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.primary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .padding(14)
            .background(AppColors.softGray)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var overlappingAvatars: some View {
        let companions = Array(CompanionCatalog.all.prefix(3))
        return ZStack(alignment: .leading) {
            ForEach(Array(companions.enumerated()), id: \.element.id) { index, companion in
                CompanionAvatarView(companion: companion, size: 36)
                    .overlay(Circle().stroke(AppColors.white, lineWidth: 2))
                    .offset(x: CGFloat(index) * 22)
            }
        }
        .frame(width: 36 + CGFloat(max(companions.count - 1, 0)) * 22, height: 36, alignment: .leading)
    }

    private func galleryCell(index: Int) -> some View {
        let selected = selectedPhotoIndex == index
        return Button {
            selectedPhotoIndex = index
        } label: {
            CompanionPortraitView(
                companion: appState.selectedCompanion,
                cornerRadius: 14,
                photoIndex: index
            )
            .frame(height: 168)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? AppColors.primary : Color.clear, lineWidth: 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
