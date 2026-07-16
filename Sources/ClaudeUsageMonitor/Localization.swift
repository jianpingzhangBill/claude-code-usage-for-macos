import Foundation

/// Looks a key up in the app's bundled `Localizable.strings` (Bundle.module).
/// The key doubles as the English base value, so a missing translation falls
/// back to readable English rather than the raw key.
func L(_ key: String) -> String {
    Bundle.module.localizedString(forKey: key, value: key, table: nil)
}

/// `L()` + `String(format:)` for strings with runtime arguments.
func L(_ key: String, _ args: CVarArg...) -> String {
    String(format: L(key), locale: Locale.current, arguments: args)
}
