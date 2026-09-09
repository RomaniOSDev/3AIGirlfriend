import SwiftUI

struct CompanionPickerView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(CompanionCatalog.all) { companion in
                        Button {
                            appState.selectCompanion(companion.id)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                CompanionPortraitView(companion: companion, cornerRadius: 16, showsNameOverlay: true)
                                    .frame(height: 180)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(
                                                appState.selectedCompanionID == companion.id ? AppColors.primary : .clear,
                                                lineWidth: 3
                                            )
                                    )
                                Text(companion.tag)
                                    .font(AppFonts.caption(12))
                                    .foregroundStyle(AppColors.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .clearScrollBackground()
            .background(AppColors.background)
            .navigationTitle(String(localized: "profile.companions_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.done")) { dismiss() }
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
    }
}
