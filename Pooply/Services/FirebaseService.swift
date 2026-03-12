//
//  FirebaseService.swift
//  Pooply
//
//  Firebase Firestore and Storage service
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import UIKit

class FirebaseService {
    static let shared = FirebaseService()

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

    // MARK: - User ID Helper

    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    // MARK: - User Profile

    func saveUserProfile(_ user: User, questionnaireAnswers: [String: [String]]) async throws {
        guard let userId = userId else { throw FirebaseError.notAuthenticated }

        let data: [String: Any] = [
            "name": user.name,
            "age": user.age,
            "weight": user.weight,
            "gender": user.gender,
            "questionnaireAnswers": questionnaireAnswers,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await db.collection("users").document(userId).setData(data, merge: true)
    }

    func loadUserProfile() async throws -> (user: User, answers: [String: [String]])? {
        guard let userId = userId else { throw FirebaseError.notAuthenticated }

        let doc = try await db.collection("users").document(userId).getDocument()

        guard let data = doc.data() else { return nil }

        let user = User(
            name: data["name"] as? String ?? "",
            age: data["age"] as? Int ?? 25,
            weight: data["weight"] as? Double ?? 150,
            gender: data["gender"] as? String ?? "other"
        )

        let answers = data["questionnaireAnswers"] as? [String: [String]] ?? [:]

        return (user, answers)
    }

    // MARK: - Logs

    func saveLog(_ log: Log) async throws {
        guard let userId = userId else { throw FirebaseError.notAuthenticated }

        var data: [String: Any] = [
            "id": log.id.uuidString,
            "poopScore": log.poopScore.rawValue,
            "type": log.type.rawValue,
            "color": log.color.rawValue,
            "size": log.size.rawValue,
            "bloodPercentage": log.bloodPercentage,
            "hydrationPercentage": log.hydrationPercentage as Any,
            "fiberPercentage": log.fiberPercentage as Any,
            "timestamp": Timestamp(date: log.timestamp),
            "analysis": log.analysis,
            "isManualEntry": log.isManualEntry,
            "createdAt": FieldValue.serverTimestamp()
        ]

        if let imageURL = log.imageURL {
            data["imageURL"] = imageURL
        }

        try await db.collection("users").document(userId)
            .collection("logs").document(log.id.uuidString).setData(data)
    }

    func loadLogs() async throws -> [Log] {
        guard let userId = userId else { throw FirebaseError.notAuthenticated }

        let snapshot = try await db.collection("users").document(userId)
            .collection("logs")
            .order(by: "timestamp", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> Log? in
            let data = doc.data()

            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let poopScoreRaw = data["poopScore"] as? String,
                  let poopScore = Log.PoopCategory(rawValue: poopScoreRaw),
                  let typeRaw = data["type"] as? String,
                  let type = Log.PoopType(rawValue: typeRaw),
                  let colorRaw = data["color"] as? String,
                  let color = Log.PoopColor(rawValue: colorRaw),
                  let sizeRaw = data["size"] as? String,
                  let size = Log.PoopSize(rawValue: sizeRaw),
                  let timestamp = (data["timestamp"] as? Timestamp)?.dateValue()
            else { return nil }

            return Log(
                id: id,
                poopScore: poopScore,
                type: type,
                color: color,
                size: size,
                bloodPercentage: data["bloodPercentage"] as? Double ?? 0,
                hydrationPercentage: data["hydrationPercentage"] as? Double,
                fiberPercentage: data["fiberPercentage"] as? Double,
                timestamp: timestamp,
                analysis: data["analysis"] as? String ?? "",
                imageURL: data["imageURL"] as? String,
                isManualEntry: data["isManualEntry"] as? Bool ?? true
            )
        }
    }

    func deleteLog(_ logId: UUID) async throws {
        guard let userId = userId else { throw FirebaseError.notAuthenticated }

        try await db.collection("users").document(userId)
            .collection("logs").document(logId.uuidString).delete()
    }

    func updateLog(_ log: Log) async throws {
        // Just save again - Firestore setData overwrites
        try await saveLog(log)
    }

    func updateLogImageURL(_ logId: UUID, url: String) async throws {
        guard let userId = userId else { throw FirebaseError.notAuthenticated }

        try await db.collection("users").document(userId)
            .collection("logs").document(logId.uuidString)
            .updateData(["imageURL": url])
    }

    // MARK: - Image Storage

    func uploadImage(_ image: UIImage, for logId: UUID) async throws -> String {
        guard let userId = userId else { throw FirebaseError.notAuthenticated }
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw FirebaseError.invalidImage
        }

        let path = "users/\(userId)/images/\(logId.uuidString).jpg"
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()

        return url.absoluteString
    }

    func deleteImage(for logId: UUID) async throws {
        guard let userId = userId else { throw FirebaseError.notAuthenticated }

        let path = "users/\(userId)/images/\(logId.uuidString).jpg"
        let ref = storage.reference().child(path)

        try await ref.delete()
    }

    // MARK: - Invite Codes

    func validateInviteCode(_ code: String) async throws -> Bool {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let doc = try await db.collection("inviteCodes").document(normalizedCode).getDocument()

        guard let data = doc.data() else { return false }

        let isActive = data["isActive"] as? Bool ?? false
        let maxUses = data["maxUses"] as? Int ?? 0
        let currentUses = data["currentUses"] as? Int ?? 0

        return isActive && currentUses < maxUses
    }

    func redeemInviteCode(_ code: String) async throws {
        guard let userId = userId else { throw FirebaseError.notAuthenticated }

        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let docRef = db.collection("inviteCodes").document(normalizedCode)

        try await docRef.updateData([
            "currentUses": FieldValue.increment(Int64(1)),
            "redeemedBy": FieldValue.arrayUnion([userId])
        ])
    }

    // MARK: - Sync All Logs (for initial load)

    func syncLogs(with localLogs: [Log]) async throws {
        // Upload local logs that might not be in cloud
        for log in localLogs {
            try await saveLog(log)
        }
    }
}

// MARK: - Errors

enum FirebaseError: LocalizedError {
    case notAuthenticated
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .invalidImage:
            return "Could not process image"
        }
    }
}
