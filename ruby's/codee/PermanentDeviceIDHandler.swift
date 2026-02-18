import Foundation
import Security

class PermanentDeviceIDHandler {
    
    static let shared = PermanentDeviceIDHandler()
    private let key = "com.app.uniqueDeviceID"
    
    private init() {}
    
    /// Public function to get permanent unique ID
    func getDeviceID() -> String {
        // Check if already exists in Keychain
        if let data = readFromKeychain(key: key),
           let id = String(data: data, encoding: .utf8) {
            print("📱 Device ID (Existing): \(id)")
            return id
        }
        
        // Generate new ID and save
        let newID = UUID().uuidString
        saveToKeychain(key: key, data: Data(newID.utf8))
        
        print("🆕 Device ID (Generated): \(newID)")
        return newID
    }
}


// MARK: - Keychain Helpers
extension PermanentDeviceIDHandler {
    
    private func saveToKeychain(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)    // Remove old value if exists
        SecItemAdd(query as CFDictionary, nil)  // Save new
    }
    
    private func readFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
}
