//
//  AuthService.swift
//  Pooply
//
//  Firebase Authentication service
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var user: FirebaseAuth.User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // For Apple Sign In
    private var currentNonce: String?

    private init() {
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }

    // MARK: - Email/Password Auth

    func signUp(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            user = result.user
            isAuthenticated = true
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = mapAuthError(error)
            throw error
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            user = result.user
            isAuthenticated = true
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = mapAuthError(error)
            throw error
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        user = nil
        isAuthenticated = false
    }

    /// Permanently deletes the signed-in Firebase Auth account. Caller is
    /// responsible for wiping Firestore data first (via
    /// `FirebaseService.deleteAllUserData()`). May throw
    /// `requiresRecentLogin` if the user hasn't authenticated recently — in
    /// that case the UI should re-prompt for sign-in and retry.
    func deleteAuthAccount() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthError.invalidCredential
        }
        try await currentUser.delete()
        user = nil
        isAuthenticated = false
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: - Apple Sign In

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw AuthError.invalidCredential
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            isLoading = true
            do {
                let result = try await Auth.auth().signIn(with: credential)
                user = result.user
                isAuthenticated = true
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = mapAuthError(error)
                throw error
            }

        case .failure(let error):
            // User cancelled - don't show error
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                return
            }
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    // MARK: - Helper Methods

    private func mapAuthError(_ error: Error) -> String {
        let nsError = error as NSError

        switch nsError.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "This email is already registered. Try signing in instead."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Please enter a valid email address."
        case AuthErrorCode.weakPassword.rawValue:
            return "Password must be at least 6 characters."
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Please try again."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your connection."
        default:
            return error.localizedDescription
        }
    }

    // Generate random nonce for Apple Sign In
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

enum AuthError: LocalizedError {
    case invalidCredential

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple Sign In credential"
        }
    }
}
