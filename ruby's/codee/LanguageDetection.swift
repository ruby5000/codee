import Foundation

enum SupportedLanguage: String {
    case english = "en"
    case spanish = "es"
    case hindi = "hi"
}

func getCurrentAppLanguage() -> String {
    // Get the first preferred language code (e.g., "en-US" or "hi-IN")
    let preferredLanguage = Locale.preferredLanguages.first ?? "en"
    
    // Extract the language code (e.g., "en" from "en-US")
    let languageCode = String(preferredLanguage.prefix(2))
    
    // Check if it's one of the supported languages
    switch languageCode {
    case SupportedLanguage.english.rawValue,
         SupportedLanguage.spanish.rawValue,
         SupportedLanguage.hindi.rawValue:
        print("Current Language Code: \(languageCode)")
        return languageCode
    default:
        print("Current Language Code not supported: \(languageCode). Defaulting to English.")
        return SupportedLanguage.english.rawValue
    }
}
