//
//  OnboardingView.swift
//  Pooply
//
//  Unified onboarding: Welcome → 12-step questionnaire (profile + baseline) →
//  Auth → Completion. One progress bar covers all 12 questions. App logo sits
//  centered above the bar; "Step X of Y" text sits below it.
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
            MeshBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if state.showProgressBar {
                    OnboardingProgressHeader(state: state)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                ZStack {
                    switch state.phase {
                    case .welcome:
                        WelcomeContent(state: state)
                            .transition(.opacity)

                    case .inviteCode:
                        InviteCodeContent(state: state)
                            .transition(slideTransition)

                    case .questions:
                        QuestionStepContent(state: state)
                            .id("step-\(state.stepIndex)")
                            .transition(slideTransition)

                    case .auth:
                        AuthContent(state: state)
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

    // MARK: - Transitions

    private var slideTransition: AnyTransition {
        .asymmetric(
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
                    Theme.Haptics.medium()
                    state.back()
                } else if horizontal < -100 && state.phase != .completion {
                    if canSwipeForward() {
                        Theme.Haptics.medium()
                        state.next()
                    }
                }
            }
    }

    private func canSwipeForward() -> Bool {
        switch state.phase {
        case .welcome:
            return true
        case .inviteCode:
            // Mandatory gate — only advance once a valid code has been entered.
            return state.inviteCodeRedeemed
        case .questions:
            guard let step = state.currentStep else { return false }
            return state.isStepAnswered(step) || step.allowSkip
        case .auth:
            return false
        case .completion:
            return false
        }
    }
}

// MARK: - Answered helper

extension OnboardingState {
    func isStepAnswered(_ step: OnboardingStep) -> Bool {
        switch step.type {
        case .textInput:
            // Only "name" is text — must be non-empty.
            if step.id == "name" { return !name.trimmingCharacters(in: .whitespaces).isEmpty }
            return !(answers[step.id]?.first?.isEmpty ?? true)
        case .singleSelect:
            if step.id == "sex" { return !gender.isEmpty }
            return !(answers[step.id]?.isEmpty ?? true)
        case .multiSelect:
            return !(answers[step.id]?.isEmpty ?? true)
        case .agePicker:
            return true // wheel always has a value
        case .weightPicker:
            return true
        }
    }
}

// MARK: - Progress Header (logo → bar → step text → back/skip)

struct OnboardingProgressHeader: View {
    @ObservedObject var state: OnboardingState

    private var stepText: String {
        guard state.phase == .questions else { return "" }
        return "Step \(state.stepIndex + 1) of \(OnboardingState.stepCount)"
    }

    private var currentAllowsSkip: Bool {
        state.currentStep?.allowSkip ?? false
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Row 1 — chevron (left), "Step X of Y" (center), skip (right)
            HStack(spacing: 0) {
                Button(action: {
                    Theme.Haptics.medium()
                    state.back()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.Colors.textOnMesh.opacity(0.72))
                        .frame(width: 36, height: 36)
                }

                Spacer()

                Text(stepText)
                    .font(Theme.Fonts.captionBold(13))
                    .foregroundStyle(Theme.Colors.textOnMesh.opacity(0.72))
                    .contentTransition(.numericText())

                Spacer()

                // Skip button mirrors the back chevron's footprint so the step
                // text stays perfectly centered.
                if currentAllowsSkip {
                    Button(action: {
                        Theme.Haptics.light()
                        state.skipCurrent()
                    }) {
                        Text("Skip")
                            .font(Theme.Fonts.captionBold(13))
                            .foregroundStyle(Theme.Colors.textOnMesh.opacity(0.72))
                            .frame(minWidth: 36, minHeight: 36)
                            .padding(.horizontal, 4)
                    }
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
            }

            // Row 2 — Lee mascot (left) + progress bar (fills remaining width)
            HStack(spacing: 10) {
                MascotCircle(size: 40)
                    .offset(x: -2)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.45))
                            .frame(height: 10)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.babyBlue300,
                                        Theme.Colors.babyBlue400
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(10, geometry.size.width * state.progress), height: 10)
                            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: state.progress)
                    }
                }
                .frame(height: 10)
            }
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
            MascotCircle(size: 132)
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                .offset(y: 16)

//            Spacer().frame(height: Theme.Spacing.xs)

            VStack(spacing: Theme.Spacing.xs) {
                Text("Pooply")
                    .font(.custom("PlusJakartaSans-ExtraBold", size: 36))
                    .foregroundStyle(Theme.Colors.textOnMesh)

                Text("Your Gut Health Companion")
                    .font(Theme.Fonts.heading())
                    .foregroundStyle(Theme.Colors.textOnMesh.opacity(0.75))

                Text("AI-powered stool tracking for\na happier, healthier gut.")
                    .font(Theme.Fonts.body())
                    .foregroundStyle(Theme.Colors.textOnMesh.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, Theme.Spacing.xs)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            Spacer()

            Button(action: {
                Theme.Haptics.medium()
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

// MARK: - Survey Header (question title + subtitle)

struct SurveyMascotHeader: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("PlusJakartaSans-ExtraBold", size: 26))
                .foregroundStyle(Theme.Colors.textOnMesh)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(Theme.Fonts.body(14))
                    .foregroundStyle(Theme.Colors.textOnMesh.opacity(0.7))
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Unified Question Step

struct QuestionStepContent: View {
    @ObservedObject var state: OnboardingState
    @FocusState private var nameFieldFocused: Bool

    /// Local working state for multi-select. We mirror to `state.answers` on Continue.
    @State private var multiSelection: Set<String> = []

    private var step: OnboardingStep {
        // currentStep can be nil only on the boundary; falling back to a
        // dummy keeps SwiftUI from crashing during the dissolve.
        state.currentStep ?? state.steps[0]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            contentArea

            Button(action: handleContinue) {
                Text("Continue")
                    .font(Theme.Fonts.bodyBold())
            }
            .elevatedButtonStyle(
                color: continueDisabled ? Theme.Colors.neutral400 : Theme.Colors.neutral900,
                height: 56
            )
            .animation(.easeInOut(duration: 0.2), value: continueDisabled)
            .disabled(continueDisabled)
            .opacity(continueDisabled ? 0.6 : 1)
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            Analytics.logEvent("onboarding_step", parameters: [
                "step_index": state.stepIndex,
                "step_id": step.id
            ])
            syncLocalState()
            if step.type == .textInput {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    nameFieldFocused = true
                }
            }
        }
        .onChange(of: state.stepIndex) { _, _ in
            syncLocalState()
        }
    }

    // MARK: - Layout

    /// True for steps with long option lists that should scroll. False for
    /// "simple" steps (name, age, weight) — those center vertically.
    private var needsScroll: Bool {
        switch step.type {
        case .singleSelect, .multiSelect: return true
        case .textInput, .agePicker, .weightPicker: return false
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        if needsScroll {
            // Title pinned at top; options scroll independently so the view
            // doesn't stretch when there are 6–7 choices.
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                SurveyMascotHeader(title: step.title, subtitle: step.subtitle)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.top, Theme.Spacing.lg)

                ScrollView(.vertical, showsIndicators: false) {
                    stepInput
                        .padding(.horizontal, Theme.Spacing.screenHorizontal)
                        .padding(.bottom, Theme.Spacing.md)
                }
            }
        } else {
            // Simple, single-element steps (name / age / weight) — center the
            // title + input between two flexible spacers.
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Spacer()

                SurveyMascotHeader(title: step.title, subtitle: step.subtitle)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                stepInput
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                Spacer()
            }
        }
    }

    // MARK: - Step Inputs

    @ViewBuilder
    private var stepInput: some View {
        switch step.type {
        case .textInput:
            nameInput
        case .singleSelect:
            singleSelectOptions
        case .multiSelect:
            multiSelectOptions
        case .agePicker:
            agePicker
        case .weightPicker:
            weightPicker
        }
    }

    private var nameInput: some View {
        TextField("Enter your name", text: $state.name)
            .font(Theme.Fonts.body())
            .foregroundStyle(Theme.Colors.textOnGlass)
            .padding(Theme.Spacing.md)
            .glassSurface(radius: Theme.Radius.medium)
            .focused($nameFieldFocused)
            .submitLabel(.done)
            .onSubmit {
                nameFieldFocused = false
                if !state.name.isEmpty { state.next() }
            }
    }

    private var singleSelectOptions: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(step.options, id: \.self) { option in
                AnswerOptionButton(
                    title: option,
                    isSelected: isSingleSelected(option),
                    action: { selectSingle(option) }
                )
            }
        }
    }

    private var multiSelectOptions: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(step.options, id: \.self) { option in
                AnswerOptionButton(
                    title: option,
                    isSelected: multiSelection.contains(option),
                    action: { toggleMulti(option) }
                )
            }
        }
    }

    private var agePicker: some View {
        Picker("Age", selection: $state.age) {
            ForEach(13..<100, id: \.self) { age in
                Text("\(age) years").tag(age)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .glassSurface(radius: Theme.Radius.medium)
    }

    private var weightPicker: some View {
        Picker("Weight", selection: $state.weight) {
            ForEach(Array(stride(from: 80.0, through: 400.0, by: 5.0)), id: \.self) { weight in
                Text("\(Int(weight)) lbs").tag(weight)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .glassSurface(radius: Theme.Radius.medium)
    }

    // MARK: - Selection helpers

    private func isSingleSelected(_ option: String) -> Bool {
        if step.id == "sex" {
            return state.gender == option
        }
        return state.answers[step.id]?.first == option
    }

    private func selectSingle(_ option: String) {
        Theme.Haptics.light()
        withAnimation(Theme.Animation.spring) {
            if step.id == "sex" {
                state.gender = option
            } else {
                state.answers[step.id] = [option]
            }
        }
    }

    private func toggleMulti(_ option: String) {
        Theme.Haptics.light()
        withAnimation(Theme.Animation.spring) {
            // "None" is mutually-exclusive with the rest for the symptoms list.
            if option == "None" {
                multiSelection = multiSelection.contains("None") ? [] : ["None"]
            } else {
                multiSelection.remove("None")
                if multiSelection.contains(option) {
                    multiSelection.remove(option)
                } else {
                    multiSelection.insert(option)
                }
            }
        }
        // Mirror selection back to OnboardingState so `continueDisabled` (which
        // reads `state.answers`) recomputes immediately. Without this the
        // Continue button stays disabled until the next tap cycle.
        state.answers[step.id] = Array(multiSelection)
    }

    private func syncLocalState() {
        if step.type == .multiSelect {
            multiSelection = Set(state.answers[step.id] ?? [])
        } else {
            multiSelection = []
        }
    }

    // MARK: - Continue

    private var continueDisabled: Bool {
        if step.allowSkip {
            // Even on skippable steps, the Continue button requires a selection —
            // the dedicated Skip control in the header handles the empty path.
            return !state.isStepAnswered(step)
        }
        return !state.isStepAnswered(step)
    }

    private func handleContinue() {
        Theme.Haptics.medium()
        nameFieldFocused = false

        if step.type == .multiSelect {
            state.answers[step.id] = Array(multiSelection)
        }
        state.next()
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

            HStack(spacing: Theme.Spacing.sm) {
                CompletionStat(value: "\(state.age)", label: "Age")
                CompletionStat(value: "\(Int(state.weight))", label: "Weight")
                CompletionStat(value: state.gender.isEmpty ? "—" : state.gender.capitalized, label: "Sex")
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .opacity(showContent ? 1 : 0)

            Spacer()

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Notification permission prompt disabled for beta — re-enable by
            // restoring the requestAuthorization wrapper around the animation
            // block below.
            // UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
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
            // }
        }
    }

    private func completeOnboarding() {
        Analytics.logEvent("onboarding_completed", parameters: [
            "invite_code_used": state.inviteCodeRedeemed
        ])
        Theme.Haptics.medium()

        // Translate the dedicated profile fields into a User. The chat-baseline
        // answers stay on `state.answers` keyed by step.id.
        let resolvedGender: String = {
            switch state.gender {
            case "Female": return "female"
            case "Male": return "male"
            case "Non-binary": return "non-binary"
            case "Prefer not to say": return "other"
            default: return state.gender.lowercased()
            }
        }()

        let user = User(
            name: state.name,
            age: state.age,
            weight: state.weight,
            gender: resolvedGender
        )

        let service = UserDefaultsService.shared
        service.saveUser(user)
        service.questionnaireAnswers = state.answers
        service.hasCompletedOnboarding = true
        service.clearOnboardingProgress()

        let answers = state.answers
        Task { try? await FirebaseService.shared.saveUserProfile(user, questionnaireAnswers: answers) }

        if state.inviteCodeRedeemed {
            SubscriptionService.shared.grantInviteAccess()

            // Now that the user is authenticated, record the redemption on the
            // invite code doc (increments currentUses, appends userId).
            let code = state.inviteCodeValue
            if !code.isEmpty {
                Task { try? await FirebaseService.shared.redeemInviteCode(code) }
            }
        }

        userViewModel.user = user

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
