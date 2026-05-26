//
//  OnboardingData.swift
//  Pooply
//
//  Unified onboarding model — profile fields and baseline-behavior questions
//  live on one ordered list so they share a single progress bar.
//

import Foundation
import SwiftUI

// MARK: - Step Definition

enum OnboardingStepType {
    case textInput
    case singleSelect
    case multiSelect
    case agePicker
    case weightPicker
}

struct OnboardingStep: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let type: OnboardingStepType
    let options: [String]
    /// Whether the user can use the "Skip this step" affordance at the top.
    let allowSkip: Bool

    static let steps: [OnboardingStep] = [
        // --- Profile (still part of the same progress bar) ---
        OnboardingStep(
            id: "name",
            title: "What's your name?",
            subtitle: "Lee will use this to make things feel personal.",
            type: .textInput,
            options: [],
            allowSkip: false
        ),
        OnboardingStep(
            id: "sex",
            title: "What's your sex?",
            subtitle: "Helps us calibrate your gut baselines.",
            type: .singleSelect,
            options: ["Female", "Male", "Non-binary", "Prefer not to say"],
            allowSkip: false
        ),
        OnboardingStep(
            id: "age",
            title: "How old are you?",
            subtitle: nil,
            type: .agePicker,
            options: [],
            allowSkip: true
        ),
        OnboardingStep(
            id: "weight",
            title: "What's your weight?",
            subtitle: nil,
            type: .weightPicker,
            options: [],
            allowSkip: true
        ),

        // --- Baseline behavior (powers Green Zone + AI chat priors) ---
        OnboardingStep(
            id: "frequency",
            title: "How often do you typically poop?",
            subtitle: "This sets your personal Green Zone baseline.",
            type: .singleSelect,
            options: [
                "Multiple times a day",
                "About once a day",
                "Every other day",
                "2–3 times a week",
                "Less than that",
                "I don't know"
            ],
            allowSkip: true
        ),
        OnboardingStep(
            id: "first_time",
            title: "When's your first poop of the day usually?",
            subtitle: nil,
            type: .singleSelect,
            options: [
                "Morning",
                "Afternoon",
                "Evening",
                "Random / no pattern",
                "I don't know"
            ],
            allowSkip: true
        ),
        OnboardingStep(
            id: "diet",
            title: "What best describes your diet?",
            subtitle: nil,
            type: .singleSelect,
            options: [
                "Omnivore",
                "Vegetarian",
                "Vegan",
                "Keto / low-carb",
                "Gluten-free",
                "Mostly processed / fast food",
                "No specific pattern"
            ],
            allowSkip: true
        ),
        OnboardingStep(
            id: "sleep",
            title: "How many hours of sleep do you usually get?",
            subtitle: nil,
            type: .singleSelect,
            options: [
                "Less than 5",
                "5–6",
                "7–8",
                "9+",
                "Varies a lot"
            ],
            allowSkip: true
        ),
        OnboardingStep(
            id: "water",
            title: "How much water do you drink daily?",
            subtitle: nil,
            type: .singleSelect,
            options: [
                "Less than 4 cups",
                "4–6 cups",
                "7–8 cups",
                "9+ cups",
                "I don't track"
            ],
            allowSkip: true
        ),
        OnboardingStep(
            id: "stress",
            title: "What's your baseline stress level?",
            subtitle: "Stress shows up in your gut.",
            type: .singleSelect,
            options: [
                "Low",
                "Moderate",
                "High",
                "Very high",
                "I don't know"
            ],
            allowSkip: true
        ),
        OnboardingStep(
            id: "symptoms",
            title: "Which symptoms do you experience regularly?",
            subtitle: "Select all that apply.",
            type: .multiSelect,
            options: [
                "Bloating",
                "Cramps",
                "Gas",
                "Heartburn",
                "Constipation",
                "Diarrhea",
                "None"
            ],
            allowSkip: true
        ),
        OnboardingStep(
            id: "goals",
            title: "What matters most to you?",
            subtitle: "Select all that apply.",
            type: .multiSelect,
            options: [
                "More energy",
                "Better mood",
                "Less bloating",
                "Weight management",
                "Skin clarity",
                "Just curious about my body"
            ],
            allowSkip: true
        )
    ]
}

// MARK: - Onboarding Phase

enum OnboardingPhase: Equatable {
    case welcome
    case inviteCode  // closed-beta gate — only valid Firestore codes proceed
    case questions   // unified profile + baseline behavior
    case auth        // sign in after questions (max investment)
    case completion

    var stringValue: String {
        switch self {
        case .welcome: return "welcome"
        case .inviteCode: return "inviteCode"
        case .questions: return "questions"
        case .auth: return "auth"
        case .completion: return "completion"
        }
    }

    static func from(string: String) -> OnboardingPhase {
        switch string {
        case "inviteCode", "invite": return .inviteCode
        case "questions", "profile", "questionnaire": return .questions
        case "auth": return .auth
        case "completion": return .completion
        default: return .welcome
        }
    }
}

// MARK: - Onboarding State

class OnboardingState: ObservableObject {
    @Published var phase: OnboardingPhase = .welcome {
        didSet { saveProgress() }
    }
    /// Index into `OnboardingStep.steps`. Persisted so a reopen doesn't reset.
    @Published var stepIndex: Int = 0 {
        didSet { saveProgress() }
    }

    // Profile data — bound to dedicated steps but stored separately so they
    // map cleanly onto the User model at completion.
    @Published var name: String = "" {
        didSet { UserDefaultsService.shared.onboardingName = name }
    }
    @Published var age: Int = 25 {
        didSet { UserDefaultsService.shared.onboardingAge = age }
    }
    @Published var weight: Double = 150 {
        didSet { UserDefaultsService.shared.onboardingWeight = weight }
    }
    @Published var gender: String = "" {
        didSet { UserDefaultsService.shared.onboardingGender = gender }
    }

    // Answers for non-profile steps. Key = step.id.
    @Published var answers: [String: [String]] = [:] {
        didSet { UserDefaultsService.shared.onboardingAnswers = answers }
    }

    // Invite code (closed-beta gate). `inviteCodeValue` holds the validated
    // code so the actual Firestore redemption can run AFTER auth, when we
    // have a userId to record on the code's `redeemedBy` array.
    @Published var inviteCodeRedeemed: Bool = false
    @Published var inviteCodeValue: String = ""

    // Slide-transition direction.
    @Published var slideDirection: Edge = .trailing

    let steps = OnboardingStep.steps
    static var stepCount: Int { OnboardingStep.steps.count }

    // MARK: - Init (restore saved progress)

    init() {
        let service = UserDefaultsService.shared
        if let savedPhase = service.onboardingPhase {
            self.phase = OnboardingPhase.from(string: savedPhase)
            self.stepIndex = min(service.onboardingStepIndex, Self.stepCount - 1)
        }
        if let savedName = service.onboardingName {
            self.name = savedName
        }
        self.age = service.onboardingAge
        self.weight = service.onboardingWeight
        if let savedGender = service.onboardingGender {
            self.gender = savedGender
        }
        if let savedAnswers = service.onboardingAnswers {
            self.answers = savedAnswers
        }
    }

    private func saveProgress() {
        let service = UserDefaultsService.shared
        service.onboardingPhase = phase.stringValue
        service.onboardingStepIndex = stepIndex
    }

    // MARK: - Step accessors

    var currentStep: OnboardingStep? {
        guard phase == .questions, stepIndex >= 0, stepIndex < steps.count else { return nil }
        return steps[stepIndex]
    }

    // MARK: - Progress

    /// 0 → 1 across the question phase. Welcome/auth/completion sit outside.
    var progress: CGFloat {
        guard phase == .questions, Self.stepCount > 1 else {
            return phase == .questions ? 0 : 1
        }
        return CGFloat(stepIndex + 1) / CGFloat(Self.stepCount)
    }

    var showProgressBar: Bool {
        phase == .questions
    }

    // MARK: - Navigation

    func next() {
        slideDirection = .trailing
        let anim: Animation = .spring(response: 0.35, dampingFraction: 0.85)

        withAnimation(anim) {
            switch phase {
            case .welcome:
                phase = .inviteCode

            case .inviteCode:
                phase = .questions
                stepIndex = 0

            case .questions:
                if stepIndex < Self.stepCount - 1 {
                    stepIndex += 1
                } else {
                    phase = .auth
                }

            case .auth:
                phase = .completion

            case .completion:
                break
            }
        }
    }

    func back() {
        slideDirection = .leading
        let anim: Animation = .spring(response: 0.35, dampingFraction: 0.85)

        withAnimation(anim) {
            switch phase {
            case .welcome:
                break

            case .inviteCode:
                phase = .welcome

            case .questions:
                if stepIndex > 0 {
                    stepIndex -= 1
                } else {
                    phase = .inviteCode
                }

            case .auth:
                phase = .questions
                stepIndex = Self.stepCount - 1

            case .completion:
                phase = .auth
            }
        }
    }

    /// Skip the currently-shown question without recording an answer.
    func skipCurrent() {
        guard let step = currentStep else { return }
        // Clear any prior answer for this step so a skipped question reads as "no answer".
        if step.type != .agePicker && step.type != .weightPicker {
            answers.removeValue(forKey: step.id)
        }
        next()
    }

    func reset() {
        phase = .welcome
        stepIndex = 0
        name = ""
        age = 25
        weight = 150
        gender = ""
        answers = [:]
        inviteCodeRedeemed = false
        inviteCodeValue = ""
        UserDefaultsService.shared.clearOnboardingProgress()
    }
}
