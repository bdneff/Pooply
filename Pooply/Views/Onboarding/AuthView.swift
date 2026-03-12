//
//  AuthView.swift
//  Pooply
//
//  Authentication screen for onboarding
//

import SwiftUI
import AuthenticationServices
import FirebaseAnalytics

struct AuthContent: View {
    @ObservedObject var state: OnboardingState
    @StateObject private var authService = AuthService.shared

    @State private var isSignUp = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var isLoading = false

    @FocusState private var focusedField: Field?

    enum Field {
        case email, password, confirmPassword
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo and title
            VStack(spacing: Theme.Spacing.sm) {
                MascotCircle(size: 80)

                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(Theme.Fonts.title())
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(isSignUp
                     ? "Start your gut health journey"
                     : "Sign in to continue")
                    .font(Theme.Fonts.body())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Spacer().frame(height: Theme.Spacing.lg)

            // Apple Sign In
            AppleSignInButton(authService: authService) {
                state.next()
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)

            // Divider
            HStack {
                Rectangle()
                    .fill(Theme.Colors.neutralLight)
                    .frame(height: 1)
                Text("or")
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.horizontal, Theme.Spacing.md)
                Rectangle()
                    .fill(Theme.Colors.neutralLight)
                    .frame(height: 1)
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .padding(.vertical, Theme.Spacing.sm)

            // Email/Password form
            VStack(spacing: Theme.Spacing.sm) {
                AuthTextField(
                    placeholder: "Email",
                    text: $email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )
                .focused($focusedField, equals: .email)

                AuthPasswordField(
                    placeholder: "Password",
                    text: $password,
                    showPassword: $showPassword
                )
                .focused($focusedField, equals: .password)

                if isSignUp {
                    AuthPasswordField(
                        placeholder: "Confirm Password",
                        text: $confirmPassword,
                        showPassword: $showPassword
                    )
                    .focused($focusedField, equals: .confirmPassword)
                }
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)

            // Error message
            if let error = authService.errorMessage {
                Text(error)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.blood)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.top, Theme.Spacing.xs)
            }

            // Toggle sign in/up
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSignUp.toggle()
                    authService.errorMessage = nil
                }
            }) {
                Text(isSignUp
                     ? "Already have an account? Sign In"
                     : "Don't have an account? Sign Up")
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.primary)
            }
            .padding(.top, Theme.Spacing.sm)

            Spacer()

            // Continue button
            Button(action: handleEmailAuth) {
                HStack(spacing: Theme.Spacing.sm) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .font(Theme.Fonts.bodyBold())
                }
            }
            .elevatedButtonStyle(color: isFormValid ? Theme.Colors.primary : Theme.Colors.neutralLight)
            .animation(.easeInOut(duration: 0.2), value: isFormValid)
            .disabled(!isFormValid || isLoading)
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .onTapGesture {
            focusedField = nil
        }
        .onAppear {
            Analytics.logEvent("onboarding_auth", parameters: nil)
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6

        if isSignUp {
            return emailValid && passwordValid && password == confirmPassword
        } else {
            return emailValid && passwordValid
        }
    }

    // MARK: - Auth Action

    private func handleEmailAuth() {
        focusedField = nil
        isLoading = true

        Task {
            do {
                if isSignUp {
                    try await authService.signUp(email: email, password: password)
                } else {
                    try await authService.signIn(email: email, password: password)
                }

                await MainActor.run {
                    Analytics.logEvent("onboarding_auth_completed", parameters: [
                        "method": "email",
                        "is_signup": isSignUp
                    ])
                    isLoading = false
                    state.next()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Apple Sign In Button (Custom — no SwiftUI wrapper issues)

struct AppleSignInButton: View {
    @ObservedObject var authService: AuthService
    let onSuccess: () -> Void

    var body: some View {
        Button(action: startAppleSignIn) {
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18, weight: .semibold))
                Text("Continue with Apple")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.black)
            .clipShape(Capsule())
        }
    }

    private func startAppleSignIn() {
        let nonce = authService.prepareAppleSignIn()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = nonce

        let delegate = AppleSignInDelegate(authService: authService, onSuccess: onSuccess)
        // Store delegate to keep it alive
        AppleSignInDelegate.current = delegate

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
    }
}

// MARK: - Apple Sign In Delegate

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static var current: AppleSignInDelegate?

    let authService: AuthService
    let onSuccess: () -> Void

    init(authService: AuthService, onSuccess: @escaping () -> Void) {
        self.authService = authService
        self.onSuccess = onSuccess
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            do {
                try await authService.handleAppleSignIn(result: .success(authorization))
                await MainActor.run {
                    Analytics.logEvent("onboarding_auth_completed", parameters: [
                        "method": "apple"
                    ])
                    onSuccess()
                }
            } catch {
                // Error handled in authService
            }
            AppleSignInDelegate.current = nil
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task {
            try? await authService.handleAppleSignIn(result: .failure(error))
            AppleSignInDelegate.current = nil
        }
    }
}

// MARK: - Auth Text Field

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(width: 20)

            TextField(placeholder, text: $text)
                .font(Theme.Fonts.body())
                .foregroundStyle(Theme.Colors.textPrimary)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .frame(height: 52)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Auth Password Field

struct AuthPasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(width: 20)

            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .font(Theme.Fonts.body())
            .foregroundStyle(Theme.Colors.textPrimary)
            .textContentType(.password)
            .autocapitalization(.none)
            .autocorrectionDisabled()

            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .frame(height: 52)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    AuthContent(state: OnboardingState())
}
