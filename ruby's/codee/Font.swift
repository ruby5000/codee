import UIKit
import CoreText

extension Constants.Fonts {
    static let HELVETICA_REGULAR = "HelveticaNeue"
    static let HELVETICA_BLACK = "HelveticaNeue-Black"
    static let HELVETICA_BOLD = "HelveticaNeue-Bold"
    static let HELVETICA_LIGHT = "HelveticaNeue-Light"
    static let HELVETICA_MEDIUM = "HelveticaNeue-Medium"
    static let HELVETICA_MEDIUM_BOLD = "HelveticaNeue-Bold"
    static let HELVETICA_THIN = "HelveticaNeue-Thin"
    static let HELVETICA_ULTRA_LIGHT = "HelveticaNeue-UltraLight"
    static let REAL_TEXT_BOLD = "RealTextBold"
    static let REAL_TEXT_MEDIUM = "RealTextMedium"
    static let GILROY_BOLD = "Gilroy-Bold"
    static let GILROY_REGULAR = "Gilroy-Regular"
    static let FIGTREE_BOLD = "Figtree-Bold"
    static let FIGTREE_MEDIUM = "Figtree-Medium"
    static let FIGTREE_REGULAR = "Figtree-Regular"
    static let BRICOLAGE_MEDIUM = "BricolageGrotesque-Medium"
    static let BRICOLAGE_BOLD = "BricolageGrotesque-Bold"
    static let BRICOLAGE_REGULAR = "BricolageGrotesque-Regular"
    static let BRICOLAGE_SEMI = "BricolageGrotesque-SemiBold"
    
    static let BUGS_LIFE = "bugsLife"
    
    /// Registers the bugsLife font from bundle if not already registered
    private static func registerBugsLifeFontIfNeeded() {
        // Check if font is already available
        let allFonts = UIFont.familyNames.flatMap { UIFont.fontNames(forFamilyName: $0) }
        let isAlreadyRegistered = allFonts.contains { $0.lowercased().contains("bugslife") || $0.lowercased().contains("bugs life") }
        
        if isAlreadyRegistered {
            return
        }
        
        // Try to load from bundle - check multiple possible paths
        var fontURL: URL?
        
        // Try main bundle root
        fontURL = Bundle.main.url(forResource: "bugsLife", withExtension: "ttf")
        
        // Try Fonts subdirectory
        if fontURL == nil {
            fontURL = Bundle.main.url(forResource: "bugsLife", withExtension: "ttf", subdirectory: "Fonts")
        }
        
        // Try Helper/Fonts subdirectory
        if fontURL == nil {
            fontURL = Bundle.main.url(forResource: "bugsLife", withExtension: "ttf", subdirectory: "Helper/Fonts")
        }
        
        guard let url = fontURL else {
            print("⚠️ bugsLife.ttf not found in bundle (checked root, Fonts/, and Helper/Fonts/)")
            return
        }
        
        guard let fontData = try? Data(contentsOf: url),
              let provider = CGDataProvider(data: fontData as CFData),
              let cgFont = CGFont(provider) else {
            print("⚠️ Failed to create font from bundle")
            return
        }
        
        // Get the PostScript name from the font file
        if let postScriptName = cgFont.postScriptName as String? {
            print("📋 Found PostScript name from font file: \(postScriptName)")
        }
        
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(cgFont, &error) {
            if let error = error?.takeRetainedValue() {
                let errorDescription = CFErrorCopyDescription(error)
                print("⚠️ Failed to register font: \(errorDescription ?? "Unknown error" as CFString)")
            }
        } else {
            if let postScriptName = cgFont.postScriptName as String? {
                print("✅ Successfully registered bugsLife font from bundle with PostScript name: \(postScriptName)")
            } else {
                print("✅ Successfully registered bugsLife font from bundle")
            }
        }
    }
    
    /// Gets the PostScript name from the font file
    private static func getPostScriptNameFromFile() -> String? {
        var fontURL: URL?
        
        fontURL = Bundle.main.url(forResource: "bugsLife", withExtension: "ttf")
        if fontURL == nil {
            fontURL = Bundle.main.url(forResource: "bugsLife", withExtension: "ttf", subdirectory: "Fonts")
        }
        if fontURL == nil {
            fontURL = Bundle.main.url(forResource: "bugsLife", withExtension: "ttf", subdirectory: "Helper/Fonts")
        }
        
        guard let url = fontURL,
              let fontData = try? Data(contentsOf: url),
              let provider = CGDataProvider(data: fontData as CFData),
              let cgFont = CGFont(provider),
              let postScriptName = cgFont.postScriptName as String? else {
            return nil
        }
        
        return postScriptName
    }
    
    /// Loads the bugsLife font with proper PostScript name resolution
    /// - Parameter size: The font size
    /// - Returns: UIFont if found, nil otherwise
    static func bugsLifeFont(size: CGFloat) -> UIFont? {
        // Register font if needed
        registerBugsLifeFontIfNeeded()
        
        // Try to get PostScript name from file first
        if let postScriptName = getPostScriptNameFromFile() {
            if let font = UIFont(name: postScriptName, size: size) {
                print("✅ Loaded bugsLife font using PostScript name from file: \(postScriptName)")
                return font
            }
        }
        
        // Get all available fonts
        let allFonts = UIFont.familyNames.flatMap { UIFont.fontNames(forFamilyName: $0) }
        
        // Try various possible names
        let possibleNames = [
            "bugsLife",
            "BugsLife",
            "BUGS_LIFE",
            "bugs-life",
            "Bugs-Life"
        ]
        
        // First try direct names
        for name in possibleNames {
            if let font = UIFont(name: name, size: size) {
                // Verify it's actually the font we want
                if font.fontName.lowercased().contains("bug") {
                    print("✅ Loaded bugsLife font: \(font.fontName)")
                    return font
                }
            }
        }
        
        // Try exact match (case insensitive) from available fonts
        let exactMatches = allFonts.filter { $0.lowercased() == BUGS_LIFE.lowercased() }
        if let exactMatch = exactMatches.first,
           let font = UIFont(name: exactMatch, size: size) {
            print("✅ Loaded bugsLife font (exact match): \(exactMatch)")
            return font
        }
        
        // Try partial match (contains "bugslife" or "bugs life")
        let partialMatches = allFonts.filter { 
            $0.lowercased().contains("bugslife") || 
            $0.lowercased().contains("bugs life") ||
            $0.lowercased().contains("bug") && $0.lowercased().contains("life")
        }
        if let partialMatch = partialMatches.first,
           let font = UIFont(name: partialMatch, size: size) {
            print("✅ Loaded bugsLife font (partial match): \(partialMatch)")
            return font
        }
        
        // Debug: Print all available fonts containing "bug" for troubleshooting
        let bugFonts = allFonts.filter { $0.lowercased().contains("bug") }
        if !bugFonts.isEmpty {
            print("📋 Available fonts containing 'bug': \(bugFonts)")
        } else {
            print("⚠️ No fonts found containing 'bug'. Available custom fonts: \(allFonts.filter { !$0.hasPrefix("Helvetica") && !$0.hasPrefix("Arial") && !$0.hasPrefix("Times") })")
        }
        
        return nil
    }
}
