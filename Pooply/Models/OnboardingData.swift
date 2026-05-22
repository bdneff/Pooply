//
//  OnboardingData.swift
//  Pooply
//
//  Data models for onboarding questionnaire
//

import Foundation
import SwiftUI

// MARK: - Gut Health Benefits (Replaces Features)

struct GutBenefit: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String

    static let benefits: [GutBenefit] = [
        GutBenefit(
            imageName: "onboard_serotonin",
            title: "Your Gut Makes You Happy",
            description: "90% of serotonin—your 'feel good' hormone—is made in your gut. When digestion is off, your mood follows."
        ),
        GutBenefit(
            imageName: "onboard_brainpower",
            title: "Think Clearly, Feel Sharp",
            description: "Brain fog, poor focus, and fatigue are signs of an unhappy gut. Digestive health directly impacts mental performance."
        ),
        GutBenefit(
            imageName: "onboard_energy",
            title: "Wake Up Energized",
            description: "Poor digestion means poor nutrient absorption. When your gut thrives, you get more energy from food all day long."
        ),
        GutBenefit(
            imageName: "onboard_immunity",
            title: "Strengthen Your Immunity",
            description: "70% of your immune system lives in your gut. A healthy microbiome is your first line of defense against illness."
        )
    ]
}

// MARK: - Questionnaire (Problem-Aware Questions)

struct OnboardingQuestion: Identifiable {
    let id: String
    let question: String
    let subtitle: String?
    let options: [String]
    let allowsMultiple: Bool

    static let questions: [OnboardingQuestion] = [
        OnboardingQuestion(
            id: "discomfort",
            question: "How often do you feel bloated or uncomfortable after eating?",
            subtitle: "Be honest—this helps us personalize your experience",
            options: ["Almost never", "Sometimes", "Often", "Almost every day"],
            allowsMultiple: false
        ),
        OnboardingQuestion(
            id: "energy",
            question: "How would you describe your energy levels?",
            subtitle: nil,
            options: ["Consistently high", "Good but crashes midday", "Often tired", "Frequently exhausted"],
            allowsMultiple: false
        ),
        OnboardingQuestion(
            id: "mood_fog",
            question: "Do you experience brain fog or mood swings?",
            subtitle: "These can be connected to gut health",
            options: ["Rarely", "Occasionally", "Frequently", "It's affecting my daily life"],
            allowsMultiple: false
        ),
        OnboardingQuestion(
            id: "regularity",
            question: "How predictable are your bowel movements?",
            subtitle: nil,
            options: ["Very regular (same time daily)", "Mostly regular", "Unpredictable", "I have no idea"],
            allowsMultiple: false
        ),
        OnboardingQuestion(
            id: "symptoms",
            question: "Which of these do you experience?",
            subtitle: "Select all that apply",
            options: ["Constipation", "Diarrhea", "Bloating & gas", "Stomach cramps", "Heartburn", "None of these"],
            allowsMultiple: true
        ),
        OnboardingQuestion(
            id: "impact",
            question: "What would better gut health mean for you?",
            subtitle: "What matters most to you",
            options: ["More energy & vitality", "Better mood & mental clarity", "Less discomfort & bloating", "Overall wellness", "I just want to understand my body"],
            allowsMultiple: false
        )
    ]
}

// MARK: - Onboarding Phase

enum OnboardingPhase: Equatable {
    case welcome
    case features
    case profile
    case questionnaire
    case auth        // Sign in after questionnaire (max investment)
    case inviteCode  // Invite code entry (between auth and completion)
    case completion

    var stringValue: String {
        switch self {
        case .welcome: return "welcome"
        case .features: return "features"
        case .profile: return "profile"
        case .questionnaire: return "questionnaire"
        case .auth: return "auth"
        case .inviteCode: return "inviteCode"
        case .completion: return "completion"
        }
    }

    static func from(string: String) -> OnboardingPhase {
        switch string {
        case "features": return .features
        case "profile": return .profile
        case "questionnaire": return .questionnaire
        case "auth": return .auth
        case "inviteCode": return .inviteCode
        case "completion": return .completion
        default: return .welcome
        }
    }
}

// MARK: - Onboarding State

class OnboardingState: ObservableObject {
    // Current phase and step within phase
    @Published var phase: OnboardingPhase = .welcome {
        didSet { saveProgress() }
    }
    @Published var featureIndex: Int = 0 {
        didSet { saveProgress() }
    }
    @Published var profileStepIndex: Int = 0 {
        didSet { saveProgress() }
    }
    @Published var questionIndex: Int = 0 {
        didSet { saveProgress() }
    }

    // Profile data
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

    // Questionnaire answers
    @Published var answers: [String: [String]] = [:] {
        didSet { UserDefaultsService.shared.onboardingAnswers = answers }
    }

    // Invite code
    @Published var inviteCodeRedeemed: Bool = false

    // Animation direction
    @Published var slideDirection: Edge = .trailing

    // Counts
    static let featureCount = GutBenefit.benefits.count
    static let profileStepCount = 4 // name, gender, age, weight
    let questions = OnboardingQuestion.questions

    // MARK: - Init (restore saved progress)

    init() {
        let service = UserDefaultsService.shared
        if let savedPhase = service.onboardingPhase {
            self.phase = OnboardingPhase.from(string: savedPhase)
            self.featureIndex = service.onboardingFeatureIndex
            self.profileStepIndex = service.onboardingProfileStepIndex
            self.questionIndex = service.onboardingQuestionIndex
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
        service.onboardingFeatureIndex = featureIndex
        service.onboardingProfileStepIndex = profileStepIndex
        service.onboardingQuestionIndex = questionIndex
    }

    // MARK: - Progress Calculation

    var totalSteps: Int {
        return 1 + Self.featureCount + Self.profileStepCount + questions.count + 1 + 1 + 1
    }

    var currentStep: Int {
        switch phase {
        case .welcome:
            return 0
        case .features:
            return 1 + featureIndex
        case .profile:
            return 1 + Self.featureCount + profileStepIndex
        case .questionnaire:
            return 1 + Self.featureCount + Self.profileStepCount + questionIndex
        case .auth:
            return 1 + Self.featureCount + Self.profileStepCount + questions.count
        case .inviteCode:
            return 1 + Self.featureCount + Self.profileStepCount + questions.count + 1
        case .completion:
            return totalSteps - 1
        }
    }

    var progress: CGFloat {
        guard totalSteps > 1 else { return 0 }
        return CGFloat(currentStep) / CGFloat(totalSteps - 1)
    }

    // Show progress bar for profile and questionnaire
    var showProgressBar: Bool {
        phase == .profile || phase == .questionnaire
    }

    // MARK: - Navigation

    func next() {
        slideDirection = .trailing

        let anim: Animation = phase == .features
            ? .easeInOut(duration: 0.25)
            : .spring(response: 0.35, dampingFraction: 0.85)

        withAnimation(anim) {
            switch phase {
            case .welcome:
                // Animated intro replaces the old welcome + 4 feature slides.
                // Jump straight to profile when the intro finishes.
                phase = .profile
                profileStepIndex = 0

            case .features:
                // Dead branch — the animated intro skips .features entirely.
                if featureIndex < Self.featureCount - 1 {
                    featureIndex += 1
                } else {
                    phase = .profile
                    profileStepIndex = 0
                }

            case .profile:
                if profileStepIndex < Self.profileStepCount - 1 {
                    profileStepIndex += 1
                } else {
                    phase = .questionnaire
                    questionIndex = 0
                }

            case .questionnaire:
                if questionIndex < questions.count - 1 {
                    questionIndex += 1
                } else {
                    phase = .auth
                }

            case .auth:
                // Invite code phase skipped for beta — go straight to completion.
                phase = .completion

            case .inviteCode:
                // Kept for compatibility; never reached.
                phase = .completion

            case .completion:
                break // Final step
            }
        }
    }

    func back() {
        slideDirection = .leading

        let anim: Animation = phase == .features
            ? .easeInOut(duration: 0.25)
            : .spring(response: 0.35, dampingFraction: 0.85)

        withAnimation(anim) {
            switch phase {
            case .welcome:
                break // Can't go back

            case .features:
                if featureIndex > 0 {
                    featureIndex -= 1
                } else {
                    phase = .welcome
                }

            case .profile:
                if profileStepIndex > 0 {
                    profileStepIndex -= 1
                }
                // No back from first profile step — the animated intro is not
                // re-enterable, so we short-circuit here.

            case .questionnaire:
                if questionIndex > 0 {
                    questionIndex -= 1
                } else {
                    phase = .profile
                    profileStepIndex = Self.profileStepCount - 1
                }

            case .auth:
                phase = .questionnaire
                questionIndex = questions.count - 1

            case .inviteCode:
                phase = .auth

            case .completion:
                // Invite code skipped — go back to auth.
                phase = .auth
            }
        }
    }

    func skipToProfile() {
        slideDirection = .trailing
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            phase = .profile
            profileStepIndex = 0
        }
    }

    func reset() {
        phase = .welcome
        featureIndex = 0
        profileStepIndex = 0
        questionIndex = 0
        name = ""
        age = 25
        weight = 150
        gender = ""
        answers = [:]
        inviteCodeRedeemed = false
        UserDefaultsService.shared.clearOnboardingProgress()
    }
}
