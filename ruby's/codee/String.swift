import Foundation
import UIKit

extension String {
    func ranges(of searchString: String) -> [Range<String.Index>] {
        var result: [Range<String.Index>] = []
        var startIndex = self.startIndex
        
        while let range = self.range(of: searchString, range: startIndex..<self.endIndex) {
            result.append(range)
            startIndex = range.upperBound
        }
        
        return result
    }
    
    /// Formats a string as a proper URL by adding https:// prefix if needed
    /// Returns a properly formatted URL string
    func formattedAsURL() -> String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If empty, return as is
        guard !trimmed.isEmpty else {
            return trimmed
        }
        
        // Check if it already has a protocol
        let lowercased = trimmed.lowercased()
        if lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://") {
            // Already has protocol, validate it's a proper URL
            if URL(string: trimmed) != nil {
                return trimmed
            } else {
                // Invalid URL format, try to fix by adding https://
                return "https://\(trimmed)"
            }
        }
        
        // No protocol, add https://
        let urlString = "https://\(trimmed)"
        
        // Validate the resulting URL
        if URL(string: urlString) != nil {
            return urlString
        }
        
        // If still invalid, return the original with https:// prefix anyway
        return urlString
    }
}
