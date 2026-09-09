import SwiftUI

enum AppFonts {
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func headline(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func bodySemibold(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func tiny(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
}
