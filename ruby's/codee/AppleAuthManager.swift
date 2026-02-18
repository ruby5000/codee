import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

protocol AppleAuthDelegate: AnyObject {
    func didCompleteAppleSignIn(email: String?)
    func didFailAppleSignIn(error: Error)
}

class AppleAuthManager: NSObject {
    static let shared = AppleAuthManager()
    weak var delegate: AppleAuthDelegate?
    
    private var currentNonce: String?

    func startSignIn() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess { fatalError("Unable to generate nonce") }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }

        return result
    }
}

extension AppleAuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization auth: ASAuthorization) {
        guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8)
        else {
            delegate?.didFailAppleSignIn(error: NSError(domain: "AppleAuth", code: 0, userInfo: nil))
            return
        }

        // Print all available Apple credential data
        print("=========================================")
        print("🍎 APPLE SIGN-IN DATA")
        print("=========================================")
        
        // User Identifier (unique, stable identifier for the user)
        print("📱 User ID: \(credential.user)")
        
        // Email
        if let email = credential.email {
            print("📧 Email: \(email)")
        } else {
            print("📧 Email: nil (not provided or user chose to hide)")
        }
        
        // Full Name Components
        if let fullName = credential.fullName {
            print("👤 Full Name Components:")
            if let givenName = fullName.givenName {
                print("   - Given Name: \(givenName)")
            }
            if let familyName = fullName.familyName {
                print("   - Family Name: \(familyName)")
            }
            if let middleName = fullName.middleName {
                print("   - Middle Name: \(middleName)")
            }
            if let namePrefix = fullName.namePrefix {
                print("   - Name Prefix: \(namePrefix)")
            }
            if let nameSuffix = fullName.nameSuffix {
                print("   - Name Suffix: \(nameSuffix)")
            }
            if let nickname = fullName.nickname {
                print("   - Nickname: \(nickname)")
            }
            
            // Formatted full name
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .long
            let formattedName = formatter.string(from: fullName)
            print("   - Formatted Name: \(formattedName)")
            print("✅ Apple Full Name: \(formattedName)")
            UserDefaults.standard.set(formattedName, forKey: Constants.UD.USER_FULL_NAME)
        } else {
            print("👤 Full Name: nil (not provided)")
        }
        
        // Identity Token
        print("🔑 Identity Token (Base64): \(idToken.prefix(50))...")
        print("🔑 Identity Token Length: \(idToken.count) characters")
        
        // Authorization Code
        if let authCode = credential.authorizationCode {
            if let authCodeString = String(data: authCode, encoding: .utf8) {
                print("🔐 Authorization Code: \(authCodeString.prefix(50))...")
            } else {
                print("🔐 Authorization Code: \(authCode.base64EncodedString().prefix(50))... (Base64)")
            }
            print("🔐 Authorization Code Length: \(authCode.count) bytes")
        } else {
            print("🔐 Authorization Code: nil")
        }
        
        // State
        if let state = credential.state {
            print("📝 State: \(state)")
        } else {
            print("📝 State: nil")
        }
        
        // Real User Status
        print("✅ Real User Status: \(credential.realUserStatus.rawValue)")
        switch credential.realUserStatus {
        case .likelyReal:
            print("   → User is likely real")
        case .unknown:
            print("   → Real user status unknown")
        case .unsupported:
            print("   → Real user status not supported")
        @unknown default:
            print("   → Unknown status")
        }
        
        // Identity Token Data (raw)
        print("📦 Identity Token Data Length: \(tokenData.count) bytes")
        
        print("=========================================")

        let credentials = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idToken,
            rawNonce: nonce,
            accessToken: nil
        )

        Auth.auth().signIn(with: credentials) { result, error in
            if let error = error {
                self.delegate?.didFailAppleSignIn(error: error)
                return
            }
            
            let appleEmail = credential.email
            let firebaseEmail = result?.user.email
            let finalEmail = appleEmail ?? firebaseEmail
            
            self.delegate?.didCompleteAppleSignIn(email: finalEmail)
            
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Check if error is cancellation
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            print("⚠️ Apple Sign-In cancelled by user")
            // Return a cancellation error that can be identified
            let cancelError = NSError(domain: "AppleAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User cancelled"])
            delegate?.didFailAppleSignIn(error: cancelError)
            return
        }
        delegate?.didFailAppleSignIn(error: error)
    }
}

extension AppleAuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        fatalError("No valid window scene found")
    }

}
