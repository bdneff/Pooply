//
//  OnboardingView.swift
//  Pooply
//
//  Single-screen onboarding with animated content transitions
//

import SwiftUI
import UserNotifications
import FirebaseAnalytics

struct OnboardingView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var state = OnboardingState()
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Questionnaire Progress Header
                if state.showProgressBar {
                    OnboardingProgressHeader(state: state)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // MARK: - Main Content
                ZStack {
                    switch state.phase {
                    case .welcome:
                        WelcomeContent(state: state)
                            .transition(slideTransition)

                    case .features:
                        // Only the content slides, not the header
                        FeatureSlideContent(state: state)
                            .id("feature-\(state.featureIndex)")
                            .transition(slideTransition)

                    case .auth:
                        AuthContent(state: state)
                            .transition(slideTransition)

                    case .inviteCode:
                        InviteCodeContent(state: state)
                            .transition(slideTransition)

                    case .profile:
                        ProfileStepContent(state: state)
                            .id("profile-\(state.profileStepIndex)")
                            .transition(slideTransition)

                    case .questionnaire:
                        QuestionnaireContent(state: state)
                            .id("question-\(state.questionIndex)")
                            .transition(slideTransition)

                    case .completion:
                        CompletionContent(
                            state: state,
                            hasCompletedOnboarding: $hasCompletedOnboarding,
                            userViewModel: userViewModel
                        )
                        .transition(slideTransition)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .gesture(swipeGesture)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Theme.Colors.tealTint.opacity(state.phase == .welcome ? 1 : 0.3),
                Theme.Colors.background,
                Theme.Colors.background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: 0.5), value: state.phase)
    }

    // MARK: - Transitions

    private var slideTransition: AnyTransition {
        // Features use crossfade+scale so images/glows don't slide out of sync
        if state.phase == .features {
            return .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.96)),
                removal: .opacity.combined(with: .scale(scale: 0.96))
            )
        }
        return .asymmetric(
            insertion: .move(edge: state.slideDirection == .trailing ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: state.slideDirection == .trailing ? .leading : .trailing).combined(with: .opacity)
        )
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                let horizontal = value.translation.width

                if horizontal > 100 && state.phase != .welcome {
                    // Swipe right - go back
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    state.back()
                } else if horizontal < -100 && state.phase != .completion {
                    // Swipe left - go forward (if allowed)
                    if canSwipeForward() {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        state.next()
                    }
                }
            }
    }

    private func canSwipeForward() -> Bool {
        switch state.phase {
        case .welcome:
            return true
        case .features:
            return true
        case .auth:
            return false // Must complete auth via buttons
        case .inviteCode:
            return false // Must use buttons
        case .profile:
            if state.profileStepIndex == 0 { return !state.name.isEmpty }
            return true
        case .questionnaire:
            return true // Allow skipping questions
        case .completion:
            return false
        }
    }
}

// MARK: - Progress Header

struct OnboardingProgressHeader: View {
    @ObservedObject var state: OnboardingState

    private var stepText: String {
        switch state.phase {
        case .features:
            return "\(state.featureIndex + 1) of \(OnboardingState.featureCount)"
        case .profile:
            return "\(state.profileStepIndex + 1) of \(OnboardingState.profileStepCount)"
        case .questionnaire:
            return "\(state.questionIndex + 1) of \(state.questions.count)"
        default:
            return ""
        }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                // Back button
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

                Text(stepText)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .contentTransition(.numericText())

                Spacer()

                // Skip button (features only)
                if state.phase == .features {
                    Button(action: {
                        state.skipToProfile()
                    }) {
                        Text("Skip")
                            .font(Theme.Fonts.captionBold())
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .frame(width: 44, height: 44)
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Colors.neutralLight.opacity(0.3))
                        .frame(height: 6)

                    Capsule()
                        .fill(Theme.Colors.primary)
                        .frame(width: geometry.size.width * state.progress, height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state.progress)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, Theme.Spacing.screenHorizontal)
        .padding(.top, Theme.Spacing.sm)
        .padding(.bottom, Theme.Spacing.md)
    }
}

// MARK: - Welcome Content

struct WelcomeContent: View {
    @ObservedObject var state: OnboardingState

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Mascot
            MascotCircle(size: 160)
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)

            Spacer().frame(height: Theme.Spacing.lg)

            // Title + copy
            VStack(spacing: Theme.Spacing.xs) {
                Text("Pooply")
                    .font(.custom("Nunito-Bold", size: 36))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Your Gut Health Companion")
                    .font(Theme.Fonts.heading())
                    .foregroundStyle(Theme.Colors.textSecondary)

                Text("AI-powered stool tracking for\na happier, healthier gut")
                    .font(Theme.Fonts.body())
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Theme.Spacing.xs)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            Spacer()

            // Get Started button
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                state.next()
            }) {
                Text("Get Started")
                    .font(Theme.Fonts.bodyBold())
            }
            .elevatedButtonStyle()
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)

            Spacer().frame(height: Theme.Spacing.xxl)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: appeared)
        .onAppear {
            Analytics.logEvent("onboarding_welcome", parameters: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                appeared = true
            }
        }
    }
}

// MARK: - Benefit Slide Content (Image on top, copy underneath, button + dots at bottom)

struct FeatureSlideContent: View {
    @ObservedObject var state: OnboardingState

    @State private var showContent = false

    private var benefit: GutBenefit {
        GutBenefit.benefits[state.featureIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Image with padding and rounded corners
            Image(benefit.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.96)

            // Copy section — centered, right under image
            VStack(spacing: Theme.Spacing.sm) {
                Text(benefit.title)
                    .font(Theme.Fonts.title())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(benefit.description)
                    .font(Theme.Fonts.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .padding(.top, Theme.Spacing.lg)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 8)

            Spacer()

            // Continue button
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                state.next()
            }) {
                Text(state.featureIndex == OnboardingState.featureCount - 1 ? "Continue" : "Next")
                    .font(Theme.Fonts.bodyBold())
            }
            .elevatedButtonStyle()
            .padding(.horizontal, Theme.Spacing.screenHorizontal)

            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<OnboardingState.featureCount, id: \.self) { index in
                    Capsule()
                        .fill(index == state.featureIndex ? Theme.Colors.primary : Theme.Colors.neutralLight.opacity(0.5))
                        .frame(width: index == state.featureIndex ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.featureIndex)
                }
            }
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .onAppear {
            Analytics.logEvent("onboarding_feature", parameters: [
                "feature_index": state.featureIndex,
                "feature_title": benefit.title
            ])
            showContent = false
            withAnimation(.easeOut(duration: 0.25)) {
                showContent = true
            }
        }
    }
}

// MARK: - Profile Step Content (Individual pages like questionnaire)

struct ProfileStepContent: View {
    @ObservedObject var state: OnboardingState
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Theme.Spacing.lg) {
                    // Mascot
                    MascotCircle(size: 80)
                        .padding(.top, Theme.Spacing.lg)

                    // Question text + skip
                    VStack(spacing: Theme.Spacing.sm) {
                        Text(stepTitle)
                            .font(Theme.Fonts.heading())
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.md)

                        if let subtitle = stepSubtitle {
                            Text(subtitle)
                                .font(Theme.Fonts.caption())
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }

                        // Skip button (not for name — name is required)
                        if state.profileStepIndex != 0 {
                            Button(action: {
                                state.next()
                            }) {
                                Text("Skip this step")
                                    .font(Theme.Fonts.caption())
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                        }
                    }

                    // Step-specific input
                    stepContent
                        .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    // Bottom spacer
                    Spacer().frame(height: 120)
                }
            }

            // PINNED Continue button at bottom
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Theme.Colors.background.opacity(0), Theme.Colors.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 24)

                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    nameFieldFocused = false
                    state.next()
                }) {
                    Text("Continue")
                        .font(Theme.Fonts.bodyBold())
                }
                .elevatedButtonStyle(color: continueDisabled ? Theme.Colors.neutralLight : Theme.Colors.primary)
                .animation(.easeInOut(duration: 0.2), value: continueDisabled)
                .disabled(continueDisabled)
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.bottom, Theme.Spacing.lg)
                .background(Theme.Colors.background)
            }
        }
        .onAppear {
            Analytics.logEvent("onboarding_profile_\(stepEventName)", parameters: [
                "step_index": state.profileStepIndex
            ])
            if state.profileStepIndex == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    nameFieldFocused = true
                }
            }
        }
    }

    // MARK: - Step Data

    private var stepEventName: String {
        switch state.profileStepIndex {
        case 0: return "name"
        case 1: return "gender"
        case 2: return "age"
        case 3: return "weight"
        default: return "unknown"
        }
    }

    private var stepTitle: String {
        switch state.profileStepIndex {
        case 0: return "What's your name?"
        case 1: return "What's your gender?"
        case 2: return "How old are you?"
        case 3: return "What's your weight?"
        default: return ""
        }
    }

    private var stepSubtitle: String? {
        switch state.profileStepIndex {
        case 0: return "This helps us personalize your experience"
        case 1: return "This helps us provide better insights"
        case 2: return nil
        case 3: return nil
        default: return nil
        }
    }

    private var continueDisabled: Bool {
        switch state.profileStepIndex {
        case 0: return state.name.isEmpty
        default: return false
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch state.profileStepIndex {
        case 0:
            nameStep
        case 1:
            genderStep
        case 2:
            ageStep
        case 3:
            weightStep
        default:
            EmptyView()
        }
    }

    // MARK: - Step Views

    private var nameStep: some View {
        TextField("Enter your name", text: $state.name)
            .font(Theme.Fonts.body())
            .foregroundStyle(Theme.Colors.textPrimary)
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            .focused($nameFieldFocused)
            .submitLabel(.done)
            .onSubmit {
                nameFieldFocused = false
                if !state.name.isEmpty { state.next() }
            }
    }

    private var genderStep: some View {
        VStack(spacing: Theme.Spacing.sm) {
            GenderOptionButton(title: "Female", isSelected: state.gender == "female") {
                state.gender = "female"
            }
            GenderOptionButton(title: "Male", isSelected: state.gender == "male") {
                state.gender = "male"
            }
            GenderOptionButton(title: "Non-binary", isSelected: state.gender == "non-binary") {
                state.gender = "non-binary"
            }
            GenderOptionButton(title: "Prefer not to say", isSelected: state.gender == "other") {
                state.gender = "other"
            }
        }
    }

    private var ageStep: some View {
        Picker("Age", selection: $state.age) {
            ForEach(13..<100, id: \.self) { age in
                Text("\(age) years").tag(age)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 180)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var weightStep: some View {
        Picker("Weight", selection: $state.weight) {
            ForEach(Array(stride(from: 80.0, through: 400.0, by: 5.0)), id: \.self) { weight in
                Text("\(Int(weight)) lbs").tag(weight)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 180)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Questionnaire Content

struct QuestionnaireContent: View {
    @ObservedObject var state: OnboardingState

    @State private var selectedAnswers: Set<String> = []

    private var question: OnboardingQuestion {
        state.questions[state.questionIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Theme.Spacing.lg) {
                    // Mascot
                    MascotCircle(size: 80)
                        .padding(.top, Theme.Spacing.lg)

                    // Question text
                    VStack(spacing: Theme.Spacing.sm) {
                        Text(question.question)
                            .font(Theme.Fonts.heading())
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.md)

                        if let subtitle = question.subtitle {
                            Text(subtitle)
                                .font(Theme.Fonts.caption())
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }

                        Button(action: {
                            selectedAnswers = []
                            state.next()
                        }) {
                            Text("Skip this question")
                                .font(Theme.Fonts.caption())
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }

                    // Answer options
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(question.options, id: \.self) { option in
                            AnswerOptionButton(
                                title: option,
                                isSelected: selectedAnswers.contains(option),
                                action: {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()

                                    withAnimation(Theme.Animation.spring) {
                                        if question.allowsMultiple {
                                            if selectedAnswers.contains(option) {
                                                selectedAnswers.remove(option)
                                            } else {
                                                selectedAnswers.insert(option)
                                            }
                                        } else {
                                            selectedAnswers = [option]
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    // Bottom spacer so content isn't blocked by pinned button
                    Spacer().frame(height: 120)
                }
            }

            // PINNED Continue button at bottom
            VStack(spacing: 0) {
                // Fade gradient
                LinearGradient(
                    colors: [Theme.Colors.background.opacity(0), Theme.Colors.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 24)

                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    state.answers[question.id] = Array(selectedAnswers)
                    selectedAnswers = []
                    state.next()
                }) {
                    Text("Continue")
                        .font(Theme.Fonts.bodyBold())
                }
                .elevatedButtonStyle(color: selectedAnswers.isEmpty ? Theme.Colors.neutralLight : Theme.Colors.primary)
                .animation(.easeInOut(duration: 0.2), value: selectedAnswers.isEmpty)
                .disabled(selectedAnswers.isEmpty)
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.bottom, Theme.Spacing.lg)
                .background(Theme.Colors.background)
            }
        }
        .onAppear {
            Analytics.logEvent("onboarding_question", parameters: [
                "question_index": state.questionIndex,
                "question_id": question.id
            ])
            // Load existing answers if going back
            if let existing = state.answers[question.id] {
                selectedAnswers = Set(existing)
            } else {
                selectedAnswers = []
            }
        }
        .onChange(of: state.questionIndex) { _, _ in
            // Reset when question changes
            if let existing = state.answers[question.id] {
                selectedAnswers = Set(existing)
            } else {
                selectedAnswers = []
            }
        }
    }
}

// MARK: - Completion Content

struct CompletionContent: View {
    @ObservedObject var state: OnboardingState
    @Binding var hasCompletedOnboarding: Bool
    var userViewModel: UserViewModel

    @State private var ringProgress: CGFloat = 0
    @State private var showCheckmark = false
    @State private var showContent = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Animated checkmark
            ZStack {
                Circle()
                    .stroke(Theme.Colors.primary.opacity(0.2), lineWidth: 6)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(Theme.Colors.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Theme.Colors.primary)
                    .scaleEffect(showCheckmark ? 1 : 0)
                    .opacity(showCheckmark ? 1 : 0)
            }

            // Success text
            VStack(spacing: Theme.Spacing.sm) {
                Text("You're All Set!")
                    .font(Theme.Fonts.title())
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Welcome, \(state.name)")
                    .font(Theme.Fonts.body())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            // Profile summary
            HStack(spacing: Theme.Spacing.sm) {
                CompletionStat(value: "\(state.age)", label: "Age")
                CompletionStat(value: "\(Int(state.weight))", label: "Weight")
                CompletionStat(value: state.gender.capitalized, label: "Gender")
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .opacity(showContent ? 1 : 0)

            Spacer()

            // Start button
            Button(action: completeOnboarding) {
                Text("Start Tracking")
                    .font(Theme.Fonts.bodyBold())
            }
            .elevatedButtonStyle()
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            Spacer().frame(height: Theme.Spacing.xxl)
        }
        .onAppear {
            runAnimation()
        }
    }

    private func runAnimation() {
        Analytics.logEvent("onboarding_completion", parameters: nil)
        withAnimation(.easeInOut(duration: 1.0)) {
            ringProgress = 1
        }

        // Request push notification permission after 0.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        showCheckmark = true
                    }
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.success)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showContent = true
                        }
                    }
                }
            }
        }
    }

    private func completeOnboarding() {
        Analytics.logEvent("onboarding_completed", parameters: [
            "invite_code_used": state.inviteCodeRedeemed
        ])
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Create user
        let user = User(
            name: state.name,
            age: state.age,
            weight: state.weight,
            gender: state.gender
        )

        // Save to UserDefaults
        let service = UserDefaultsService.shared
        service.saveUser(user)
        service.questionnaireAnswers = state.answers
        service.hasCompletedOnboarding = true
        service.clearOnboardingProgress()

        // Save to Firestore
        let answers = state.answers
        Task { try? await FirebaseService.shared.saveUserProfile(user, questionnaireAnswers: answers) }

        // Grant invite access if code was redeemed
        if state.inviteCodeRedeemed {
            SubscriptionService.shared.grantInviteAccess()
        }

        // Update UserViewModel
        userViewModel.user = user

        // Trigger transition to main app
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environmentObject(
            UserViewModel(
                user: User(name: "", age: 25, weight: 150, gender: "female"),
                withDummyData: false
            )
        )
}
