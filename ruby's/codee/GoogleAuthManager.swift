import Foundation
import UIKit
import GoogleSignIn
import FirebaseAuth

final class GoogleAuthManager {

    static let shared = GoogleAuthManager()
    private init() {}

    func login(from vc: UIViewController,
               completion: @escaping (Result<User, Error>) -> Void) {

        guard GIDSignIn.sharedInstance.configuration != nil else {
            completion(.failure(NSError(
                domain: "GoogleAuth",
                code: 1000,
                userInfo: [NSLocalizedDescriptionKey: "Missing Google Sign-In configuration"]
            )))
            return
        }

        // 🔥 FORCE fresh session (prevents ID token expired)
        GIDSignIn.sharedInstance.signOut()

        GIDSignIn.sharedInstance.signIn(withPresenting: vc) { result, error in

            // 1️⃣ User cancelled
            if result == nil && error == nil {
                completion(.failure(NSError(
                    domain: "GoogleAuth",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "User cancelled"]
                )))
                return
            }

            // 2️⃣ Google Sign-In error
            if let error = error as NSError? {
                let desc = error.localizedDescription.lowercased()

                if error.code == -5 || desc.contains("cancel") {
                    completion(.failure(NSError(
                        domain: "GoogleAuth",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "User cancelled"]
                    )))
                    return
                }

                if desc.contains("token expired") {
                    // 🔁 Clean stale state
                    GIDSignIn.sharedInstance.signOut()
                    completion(.failure(NSError(
                        domain: "GoogleAuth",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Session expired. Please try again."]
                    )))
                    return
                }

                completion(.failure(error))
                return
            }

            // 3️⃣ Extract tokens
            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                completion(.failure(NSError(
                    domain: "GoogleAuth",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "Missing Google ID Token"]
                )))
                return
            }

            let accessToken = user.accessToken.tokenString

            // 4️⃣ Firebase credential
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            // 5️⃣ Firebase Sign-In
            Auth.auth().signIn(with: credential) { authResult, error in

                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    completion(.failure(NSError(
                        domain: "FirebaseAuth",
                        code: 1002,
                        userInfo: [NSLocalizedDescriptionKey: "No user returned"]
                    )))
                    return
                }

                completion(.success(firebaseUser))
            }
        }
    }
}
