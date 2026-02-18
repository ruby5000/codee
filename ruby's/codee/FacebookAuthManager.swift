import Foundation
import FirebaseAuth
import FacebookLogin

class FacebookAuthManager: NSObject {
    static let shared = FacebookAuthManager()
    private let loginManager = LoginManager()
    
    // Optional: Store pending credential temporarily (in memory)
    var pendingCredentialForLinking: AuthCredential?
    
    func login(from vc: UIViewController, completion: @escaping (Result<String?, Error>) -> Void) {
        loginManager.logIn(permissions: [
            "email",
            "public_profile",
            "pages_show_list",
        ], from: vc) { result, error in
            
            // Handle error 304 (permissions mismatch) - try to proceed if we have a token
            if let error = error {
                let nsError = error as NSError
                print("❌ Facebook login error: \(error.localizedDescription)")
                print("   Error code: \(nsError.code), domain: \(nsError.domain)")
                
                // Error 304: Permissions mismatch, but we might still have a valid token
                if nsError.domain == "com.facebook.sdk.login" && nsError.code == 304 {
                    print("⚠️ Error 304 detected - checking if we have a valid token anyway...")
                    
                    // Check if we have an access token despite the error
                    if let tokenString = AccessToken.current?.tokenString {
                        print("✅ Found access token despite error 304, proceeding with login")
                        print("   Token: \(tokenString.prefix(20))...")
                        self.fetchFacebookUserDetails()
                        self.firebaseLogin(with: tokenString, completion: completion)
                        return
                    }
                }
                
                completion(.failure(error))
                return
            }
            
            guard let result = result, !result.isCancelled else {
                print("⚠️ Facebook login cancelled")
                // Return a cancellation error with code -1 to identify it
                completion(.failure(NSError(domain: "FacebookAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User cancelled"])))
                return
            }
            
            guard let tokenString = AccessToken.current?.tokenString else {
                print("❌ Missing Facebook access token")
                completion(.failure(NSError(domain: "FacebookAuth", code: 2, userInfo: [NSLocalizedDescriptionKey: "Facebook token missing."])))
                return
            }
            
            print("✅ Facebook login success. Token: \(tokenString.prefix(20))...")
            self.fetchFacebookUserDetails()
            self.firebaseLogin(with: tokenString, completion: completion)
        }
    }
    
    private func firebaseLogin(with tokenString: String, completion: @escaping (Result<String?, Error>) -> Void) {
        let credential = FacebookAuthProvider.credential(withAccessToken: tokenString)
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error as NSError? {
                // Handle account conflict
                if error.code == AuthErrorCode.accountExistsWithDifferentCredential.rawValue,
                   let email = error.userInfo[AuthErrorUserInfoEmailKey] as? String,
                   let pendingCredential = error.userInfo[AuthErrorUserInfoUpdatedCredentialKey] as? AuthCredential {
                    
                    print("⚠️ Account already exists with different credential. Email: \(email)")
                    
                    // Save credential temporarily to link later
                    self.pendingCredentialForLinking = pendingCredential
                    
                    // Check what providers are linked to the existing account
                    Auth.auth().fetchSignInMethods(forEmail: email) { methods, fetchError in
                        if let fetchError = fetchError {
                            print("❌ Failed to fetch sign-in methods: \(fetchError.localizedDescription)")
                            completion(.failure(fetchError))
                            return
                        }
                        
                        guard let methods = methods, !methods.isEmpty else {
                            print("❌ No sign-in methods returned from Firebase")
                            completion(.failure(NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "This email is already linked to Google. Please log in with Google."])))
                            return
                        }
                        
                        let message = self.messageForSignInProvider(email: email, methods: methods)
                        
                        // Pass back a custom error for UI to display
                        let customError = NSError(domain: "FirebaseMerge", code: 409, userInfo: [
                            NSLocalizedDescriptionKey: message,
                            "mergeEmail": email
                        ])
                        completion(.failure(customError))
                    }
                    return
                }
                
                // Generic Firebase sign-in error
                print("❌ Firebase signIn failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("✅ Firebase sign-in success with Facebook")
            
            // Optionally fetch email from Facebook
            GraphRequest(graphPath: "me", parameters: ["fields": "id,name,email"]).start { _, result, error in
                if let error = error {
                    print("❌ Facebook Graph error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                if let data = result as? [String: Any],
                   let email = data["email"] as? String {
                    print("✅ Facebook email fetched: \(email)")
                    completion(.success(email))
                } else {
                    print("⚠️ Email not available in Facebook profile")
                    completion(.success(nil))
                }
            }
        }
    }
    
    private func messageForSignInProvider(email: String, methods: [String]) -> String {
        guard let method = methods.first else {
            return "This email is already registered. Please sign in using the original method to link your Facebook account."
        }
        
        switch method {
        case "google.com":
            return "This email (\(email)) is already registered with Google. Please sign in using your Google account first to link Facebook."
        case "password":
            return "This email (\(email)) is registered with Email & Password. Please log in using that method first."
        case "apple.com":
            return "This email is already linked to Apple. Please log in with Google."
        default:
            return "This email (\(email)) is already in use. Please sign in with the original provider."
        }
    }
    
    // Call this after the user logs in with the correct provider (e.g. Google)
    func linkPendingFacebookCredential(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let pendingCredential = pendingCredentialForLinking else {
            completion(.failure(NSError(domain: "Linking", code: 0, userInfo: [NSLocalizedDescriptionKey: "No pending Facebook credential available."])))
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "Linking", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in."])))
            return
        }
        
        user.link(with: pendingCredential) { result, error in
            if let error = error {
                print("❌ Linking failed: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ Facebook successfully linked to existing user")
                self.pendingCredentialForLinking = nil
                completion(.success(()))
            }
        }
    }
}
extension FacebookAuthManager {
    
    func fetchFacebookUserDetails() {
        // 1. User Profile + Email
        let profileRequest = GraphRequest(
            graphPath: "me",
            parameters: [
                "fields": "id,name,first_name,last_name,middle_name,email,gender,birthday,link,locale,picture.width(512).height(512)"
            ]
        )
        
        profileRequest.start { _, result, error in
            if let error = error {
                print("❌ Graph profile error: \(error.localizedDescription)")
                return
            }
            
            if let data = result as? [String: Any] {
                print("📌 Facebook Profile Data:")
                for (key, value) in data {
                    print("   • \(key): \(value)")
                }
                
                // Extract and store full name
                if let fullName = data["name"] as? String {
                    print("✅ Facebook Full Name: \(fullName)")
                    UserDefaults.standard.set(fullName, forKey: Constants.UD.USER_FULL_NAME)
                }
            }
        }
        
        // 2. Pages the user manages (requires "pages_show_list")
        let pagesRequest = GraphRequest(
            graphPath: "me/accounts",
            parameters: ["fields": "id,name,access_token,category,perms"]
        )
        
        pagesRequest.start { _, result, error in
            if let error = error {
                print("❌ Graph pages error: \(error.localizedDescription)")
                return
            }
            
            if let data = result as? [String: Any] {
                print("📌 Facebook Pages Data:")
                if let pages = data["data"] as? [[String: Any]] {
                    for (index, page) in pages.enumerated() {
                        print("   🔹 Page \(index + 1):")
                        for (key, value) in page {
                            print("      • \(key): \(value)")
                        }
                    }
                } else {
                    print("   No managed pages found.")
                }
            }
        }
    }
}
