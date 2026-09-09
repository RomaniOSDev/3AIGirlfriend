import SwiftUI

struct Companion: Identifiable, Hashable {
    let id: String
    let age: Int
    let personality: String
    let gradient: [Color]
    let accentEmoji: String
    let photoAssetNames: [String]

    var name: String {
        localized("companion.\(id).name")
    }

    var tag: String {
        localized("companion.\(id).tag")
    }

    var bio: String {
        localized("companion.\(id).bio")
    }

    /// Longer profile description shown on the companion card.
    var about: String {
        localized("companion.\(id).about")
    }

    /// Dynamic catalog keys must use `stringLiteral` — interpolation becomes `companion.%@.name`.
    private func localized(_ key: String) -> String {
        String(localized: String.LocalizationValue(stringLiteral: key))
    }

    var shortLabel: String { "\(name), \(age)" }

    var primaryPhotoName: String? {
        photoAssetNames.first
    }
}

enum CompanionCatalog {
    static let all: [Companion] = [
        Companion(
            id: "emma",
            age: 23,
            personality: "warm",
            gradient: [Color(hex: 0xE8C4A8), Color(hex: 0xC48B6A)],
            accentEmoji: "☕",
            photoAssetNames: ["emma_01", "emma_02", "emma_03", "emma_04", "emma_05", "emma_06"]
        ),
        Companion(
            id: "elena",
            age: 24,
            personality: "sporty",
            gradient: [Color(hex: 0x7DD3A8), Color(hex: 0x3B82F6)],
            accentEmoji: "🎾",
            photoAssetNames: ["elena_01", "elena_02", "elena_03", "elena_04", "elena_05", "elena_06"]
        ),
        Companion(
            id: "maya",
            age: 25,
            personality: "elegant",
            gradient: [Color(hex: 0x1A1A2E), Color(hex: 0xC9A86C)],
            accentEmoji: "🌴",
            photoAssetNames: ["maya_01", "maya_02", "maya_03", "maya_04", "maya_05", "maya_06"]
        ),
        Companion(
            id: "chloe",
            age: 22,
            personality: "cozy",
            gradient: [Color(hex: 0xE8D5C4), Color(hex: 0xB08968)],
            accentEmoji: "📖",
            photoAssetNames: ["chloe_01", "chloe_02", "chloe_03", "chloe_04", "chloe_05", "chloe_06"]
        ),
        Companion(
            id: "stella",
            age: 26,
            personality: "glamorous",
            gradient: [Color(hex: 0x1C1C1E), Color(hex: 0xD4A574)],
            accentEmoji: "✨",
            photoAssetNames: ["stella_01", "stella_02", "stella_03", "stella_04", "stella_05", "stella_06"]
        ),
        Companion(
            id: "yuki",
            age: 23,
            personality: "cool",
            gradient: [Color(hex: 0x111827), Color(hex: 0xEC4899)],
            accentEmoji: "🌃",
            photoAssetNames: ["yuki_01", "yuki_02", "yuki_03", "yuki_04", "yuki_05", "yuki_06"]
        )
    ]

    static func companion(id: String) -> Companion {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}
