//
//  InviteCodeScreen.swift
//  Pooply
//
//  Invite code entry screen for onboarding
//

import SwiftUI
import FirebaseAnalytics

struct InviteCodeContent: View {
    @ObservedObject var state: OnboardingState

    @State private var code: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var shakeOffset: CGFloat = 0
    @State private var successIconScale: CGFloat = 1
    @FocusState private var isCodeFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    state.back()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .padding(.vertical, Theme.Spacing.sm)

            Spacer()

            // Mascot — tight to title (Welcome-style offset)
            MascotCircle(size: 110)

            Spacer().frame(height: Theme.Spacing.xs)

            Text("Enter your invite code")
                .font(Theme.Fonts.title())
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: Theme.Spacing.lg)

            // Code text field
            TextField("INVITE CODE", text: $code)
                .font(Theme.Fonts.body())
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .focused($isCodeFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    if !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        redeemCode()
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                        .stroke(
                            errorMessage != nil ? Theme.Colors.blood.opacity(0.5) :
                            successMessage != nil ? Theme.Colors.good.opacity(0.5) :
                            Color.clear,
                            lineWidth: 1.5
                        )
                )
                .offset(x: shakeOffset)
                .padding(.horizontal, Theme.Spacing.screenHorizontal)

            // Error / Success message area
            if let error = errorMessage {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(error)
                        .font(Theme.Fonts.caption())
                }
                .foregroundStyle(Theme.Colors.blood)
                .padding(.top, Theme.Spacing.sm)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            if let success = successMessage {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .scaleEffect(successIconScale)
                    Text(success)
                        .font(Theme.Fonts.caption())
                }
                .foregroundStyle(Theme.Colors.good)
                .padding(.top, Theme.Spacing.sm)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            Spacer()

            // Continue button — always pinned just above safe area
            Button(action: redeemCode) {
                HStack(spacing: Theme.Spacing.sm) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text("Continue")
                        .font(Theme.Fonts.bodyBold())
                }
            }
            .elevatedButtonStyle(color:
                code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || successMessage != nil
                    ? Theme.Colors.neutralLight
                    : Theme.Colors.neutral900
            )
            .animation(.easeInOut(duration: 0.2), value: code.isEmpty)
            .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || successMessage != nil)
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Analytics.logEvent("onboarding_invite_code", parameters: nil)
        }
    }

    // MARK: - Actions

    private func redeemCode() {
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty else { return }

        isCodeFieldFocused = false
        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                let isValid = try await FirebaseService.shared.validateInviteCode(trimmedCode)

                await MainActor.run {
                    if isValid {
                        handleSuccess(trimmedCode)
                    } else {
                        handleError()
                    }
                }
            } catch {
                await MainActor.run {
                    handleError()
                }
            }
        }
    }

    private func handleSuccess(_ code: String) {
        isLoading = false

        // Success haptic
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        // Show success message with animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            successMessage = "Code accepted! Welcome to Pooply."
        }

        // Confetti-like scale animation on icon
        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
            successIconScale = 1.4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                successIconScale = 1.0
            }
        }

        Analytics.logEvent("onboarding_invite_code_redeemed", parameters: nil)

        // Stash the code so completion can record the redemption AFTER auth
        // (the Firestore write needs a userId on `redeemedBy`).
        state.inviteCodeRedeemed = true
        state.inviteCodeValue = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // Auto-advance after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            state.next()
        }
    }

    private func handleError() {
        isLoading = false

        // Error haptic
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.error)

        // Show error message
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            errorMessage = "Invalid invite code. Please try again."
        }

        // Shake animation on text field
        withAnimation(.default) {
            shakeOffset = 10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.default) { shakeOffset = -8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.default) { shakeOffset = 6 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.default) { shakeOffset = -4 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { shakeOffset = 0 }
        }
    }
}
