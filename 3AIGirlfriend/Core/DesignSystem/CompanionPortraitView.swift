import SwiftUI

struct CompanionPortraitView: View {
    let companion: Companion
    var cornerRadius: CGFloat = 20
    var showsNameOverlay: Bool = false
    var photoIndex: Int = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                portraitBackground(size: geo.size)

                if showsNameOverlay {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.55)],
                        startPoint: .center,
                        endPoint: .bottom
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(companion.name)
                            .font(AppFonts.headline(18))
                            .foregroundStyle(.white)
                        Text(companion.tag)
                            .font(AppFonts.caption(12))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(12)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    @ViewBuilder
    private func portraitBackground(size: CGSize) -> some View {
        if let assetName = resolvedPhotoName {
            Image(assetName)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        } else {
            LinearGradient(
                colors: companion.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.22))
                .frame(width: size.width * 0.72, height: size.width * 0.72)
                .offset(x: size.width * 0.18, y: -size.height * 0.08)
                .blur(radius: 2)

            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: size.width * 0.42, height: size.width * 0.42)
                .offset(x: size.width * 0.08, y: size.height * 0.18)

            VStack {
                Spacer()
                Text(companion.accentEmoji)
                    .font(.system(size: min(size.width, size.height) * 0.28))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var resolvedPhotoName: String? {
        guard !companion.photoAssetNames.isEmpty else { return nil }
        let index = min(max(photoIndex, 0), companion.photoAssetNames.count - 1)
        return companion.photoAssetNames[index]
    }
}

struct CompanionAvatarView: View {
    let companion: Companion
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let assetName = companion.primaryPhotoName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: companion.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(companion.accentEmoji)
                        .font(.system(size: size * 0.45))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
