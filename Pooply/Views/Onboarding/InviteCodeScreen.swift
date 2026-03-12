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
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .padding(.vertical, Theme.Spacing.sm)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Theme.Spacing.lg) {
                    Spacer().frame(height: Theme.Spacing.lg)

                    // Mascot icon in concentric circles
                    ZStack {
                        MascotCircle(size: 72)
                    }

                    // Title and subtitle
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("Have an Invite Code?")
                            .font(Theme.Fonts.title())
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Enter your code to unlock full access\nto Pooply for free")
                            .font(Theme.Fonts.body())
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer().frame(height: Theme.Spacing.sm)

                    // Code text field
                    TextField("Enter invite code", text: $code)
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
                                .font(.system(size: 14, weight: .semibold))
                            Text(error)
                                .font(Theme.Fonts.caption())
                        }
                        .foregroundStyle(Theme.Colors.blood)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    if let success = successMessage {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .scaleEffect(successIconScale)
                            Text(success)
                                .font(Theme.Fonts.caption())
                        }
                        .foregroundStyle(Theme.Colors.good)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    // Bottom spacer for pinned button
                    Spacer().frame(height: 120)
                }
            }

            // Pinned bottom buttons
            VStack(spacing: Theme.Spacing.md) {
                // Fade gradient
                LinearGradient(
                    colors: [Theme.Colors.background.opacity(0), Theme.Colors.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)

                // Redeem Code button
                Button(action: redeemCode) {
                    HStack(spacing: Theme.Spacing.sm) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Redeem Code")
                            .font(Theme.Fonts.bodyBold())
                    }
                }
                .elevatedButtonStyle(color:
                    code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || successMessage != nil
                        ? Theme.Colors.neutralLight
                        : Theme.Colors.primary
                )
                .animation(.easeInOut(duration: 0.2), value: code.isEmpty)
                .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || successMessage != nil)
                .padding(.horizontal, Theme.Spacing.screenHorizontal)

                // Skip button
                Button(action: {
                    Analytics.logEvent("onboarding_invite_code_skipped", parameters: nil)
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    state.next()
                }) {
                    Text("I don't have a code")
                        .font(Theme.Fonts.captionBold())
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .disabled(isLoading || successMessage != nil)
                .padding(.bottom, Theme.Spacing.lg)
                .background(Theme.Colors.background)
            }
        }
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

        // Redeem the code (increment usage)
        Task { try? await FirebaseService.shared.redeemInviteCode(code) }

        // Success haptic
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        // Show success message with animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            successMessage = "Code redeemed! Enjoy full access."
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

        // Set redeemed flag
        state.inviteCodeRedeemed = true

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
