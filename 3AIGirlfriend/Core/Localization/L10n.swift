import Foundation

enum L10n {
    static func tr(_ key: String.LocalizationValue) -> String {
        String(localized: key)
    }

    static func format(_ key: String.LocalizationValue, _ args: CVarArg...) -> String {
        String(format: String(localized: key), locale: .current, arguments: args)
    }
}
