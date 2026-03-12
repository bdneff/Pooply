//
//  UserDefaultsService.swift
//  Pooply
//
//  Persistence layer for user data and app state
//

import Foundation

class UserDefaultsService {
    static let shared = UserDefaultsService()

    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private enum Keys {
        static let hasCompletedOnboarding = "pooply_hasCompletedOnboarding"
        static let userName = "pooply_userName"
        static let userAge = "pooply_userAge"
        static let userWeight = "pooply_userWeight"
        static let userGender = "pooply_userGender"
        static let questionnaireAnswers = "pooply_questionnaireAnswers"
        static let userCreatedAt = "pooply_userCreatedAt"
        static let logHistory = "pooply_logHistory"
        // Onboarding progress
        static let onboardingPhase = "pooply_onboardingPhase"
        static let onboardingFeatureIndex = "pooply_onboardingFeatureIndex"
        static let onboardingQuestionIndex = "pooply_onboardingQuestionIndex"
        static let onboardingName = "pooply_onboardingName"
        static let onboardingAge = "pooply_onboardingAge"
        static let onboardingWeight = "pooply_onboardingWeight"
        static let onboardingProfileStepIndex = "pooply_onboardingProfileStepIndex"
        static let onboardingGender = "pooply_onboardingGender"
        static let onboardingAnswers = "pooply_onboardingAnswers"
    }

    private init() {}

    // MARK: - Onboarding State

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    // MARK: - User Data

    var userName: String? {
        get { defaults.string(forKey: Keys.userName) }
        set { defaults.set(newValue, forKey: Keys.userName) }
    }

    var userAge: Int {
        get { defaults.integer(forKey: Keys.userAge) }
        set { defaults.set(newValue, forKey: Keys.userAge) }
    }

    var userWeight: Double {
        get { defaults.double(forKey: Keys.userWeight) }
        set { defaults.set(newValue, forKey: Keys.userWeight) }
    }

    var userGender: String? {
        get { defaults.string(forKey: Keys.userGender) }
        set { defaults.set(newValue, forKey: Keys.userGender) }
    }

    var userCreatedAt: Date? {
        get { defaults.object(forKey: Keys.userCreatedAt) as? Date }
        set { defaults.set(newValue, forKey: Keys.userCreatedAt) }
    }

    // MARK: - Questionnaire

    var questionnaireAnswers: [String: [String]]? {
        get {
            guard let data = defaults.data(forKey: Keys.questionnaireAnswers),
                  let answers = try? JSONDecoder().decode([String: [String]].self, from: data) else {
                return nil
            }
            return answers
        }
        set {
            if let newValue = newValue,
               let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.questionnaireAnswers)
            } else {
                defaults.removeObject(forKey: Keys.questionnaireAnswers)
            }
        }
    }

    // MARK: - Log History

    var logHistory: [Log]? {
        get {
            guard let data = defaults.data(forKey: Keys.logHistory),
                  let logs = try? JSONDecoder().decode([Log].self, from: data) else {
                return nil
            }
            return logs
        }
        set {
            if let newValue = newValue,
               let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.logHistory)
            } else {
                defaults.removeObject(forKey: Keys.logHistory)
            }
        }
    }

    // MARK: - User Helpers

    func saveUser(_ user: User) {
        userName = user.name
        userAge = user.age
        userWeight = user.weight
        userGender = user.gender
        if userCreatedAt == nil {
            userCreatedAt = Date()
        }
    }

    func loadUser() -> User? {
        guard let name = userName, !name.isEmpty,
              let gender = userGender else {
            return nil
        }
        return User(name: name, age: userAge, weight: userWeight, gender: gender)
    }

    // MARK: - Log Helpers

    func saveLogs(_ logs: [Log]) {
        logHistory = logs
    }

    func loadLogs() -> [Log] {
        return logHistory ?? []
    }

    func addLog(_ log: Log) {
        var logs = loadLogs()
        logs.append(log)
        saveLogs(logs)
    }

    // MARK: - Reset

    func clearAllData() {
        defaults.removeObject(forKey: Keys.hasCompletedOnboarding)
        defaults.removeObject(forKey: Keys.userName)
        defaults.removeObject(forKey: Keys.userAge)
        defaults.removeObject(forKey: Keys.userWeight)
        defaults.removeObject(forKey: Keys.userGender)
        defaults.removeObject(forKey: Keys.questionnaireAnswers)
        defaults.removeObject(forKey: Keys.userCreatedAt)
        defaults.removeObject(forKey: Keys.logHistory)
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }

    // MARK: - Onboarding Progress Persistence

    var onboardingPhase: String? {
        get { defaults.string(forKey: Keys.onboardingPhase) }
        set { defaults.set(newValue, forKey: Keys.onboardingPhase) }
    }

    var onboardingFeatureIndex: Int {
        get { defaults.integer(forKey: Keys.onboardingFeatureIndex) }
        set { defaults.set(newValue, forKey: Keys.onboardingFeatureIndex) }
    }

    var onboardingQuestionIndex: Int {
        get { defaults.integer(forKey: Keys.onboardingQuestionIndex) }
        set { defaults.set(newValue, forKey: Keys.onboardingQuestionIndex) }
    }

    var onboardingName: String? {
        get { defaults.string(forKey: Keys.onboardingName) }
        set { defaults.set(newValue, forKey: Keys.onboardingName) }
    }

    var onboardingAge: Int {
        get {
            let val = defaults.integer(forKey: Keys.onboardingAge)
            return val == 0 ? 25 : val
        }
        set { defaults.set(newValue, forKey: Keys.onboardingAge) }
    }

    var onboardingWeight: Double {
        get {
            let val = defaults.double(forKey: Keys.onboardingWeight)
            return val == 0 ? 150 : val
        }
        set { defaults.set(newValue, forKey: Keys.onboardingWeight) }
    }

    var onboardingProfileStepIndex: Int {
        get { defaults.integer(forKey: Keys.onboardingProfileStepIndex) }
        set { defaults.set(newValue, forKey: Keys.onboardingProfileStepIndex) }
    }

    var onboardingGender: String? {
        get { defaults.string(forKey: Keys.onboardingGender) }
        set { defaults.set(newValue, forKey: Keys.onboardingGender) }
    }

    var onboardingAnswers: [String: [String]]? {
        get {
            guard let data = defaults.data(forKey: Keys.onboardingAnswers),
                  let answers = try? JSONDecoder().decode([String: [String]].self, from: data) else {
                return nil
            }
            return answers
        }
        set {
            if let newValue = newValue,
               let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.onboardingAnswers)
            } else {
                defaults.removeObject(forKey: Keys.onboardingAnswers)
            }
        }
    }

    func clearOnboardingProgress() {
        defaults.removeObject(forKey: Keys.onboardingPhase)
        defaults.removeObject(forKey: Keys.onboardingFeatureIndex)
        defaults.removeObject(forKey: Keys.onboardingQuestionIndex)
        defaults.removeObject(forKey: Keys.onboardingName)
        defaults.removeObject(forKey: Keys.onboardingAge)
        defaults.removeObject(forKey: Keys.onboardingWeight)
        defaults.removeObject(forKey: Keys.onboardingProfileStepIndex)
        defaults.removeObject(forKey: Keys.onboardingGender)
        defaults.removeObject(forKey: Keys.onboardingAnswers)
    }
}
