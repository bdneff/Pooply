//
//  AnalysisService.swift
//  Pooply
//
//  Calls Firebase Cloud Function to analyze poop images with OpenAI
//

import Foundation
import FirebaseFunctions
import UIKit

class AnalysisService {
    static let shared = AnalysisService()

    private lazy var functions = Functions.functions()

    private init() {}

    // MARK: - Analyze Image

    /// Analyzes a poop image using OpenAI Vision via Firebase Cloud Function
    /// Returns analysis result matching our Log model structure
    func analyzeImage(_ image: UIImage) async throws -> AnalysisResult {
        // Resize to max 1024px on longest side to reduce OpenAI token cost
        let resized = image.resizedForAnalysis(maxDimension: 1024)
        guard let imageData = resized.jpegData(compressionQuality: 0.7) else {
            throw AnalysisError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()

        // Call Firebase Cloud Function
        let data: [String: Any] = [
            "image": base64Image
        ]

        do {
            let result = try await functions.httpsCallable("analyzePoopImage").call(data)

            guard let resultData = result.data as? [String: Any] else {
                throw AnalysisError.invalidResponse
            }

            return try parseAnalysisResult(resultData)
        } catch {
            // Check if it's a Functions error
            if let error = error as NSError?,
               error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                let message = error.localizedDescription

                // Check for invalid image content (not poop)
                if code == .invalidArgument && message.contains("stool") {
                    throw AnalysisError.notStoolImage
                }

                throw AnalysisError.functionError(message)
            }
            throw error
        }
    }

    // MARK: - Parse Result

    private func parseAnalysisResult(_ data: [String: Any]) throws -> AnalysisResult {
        guard let typeRaw = data["type"] as? String,
              let type = Log.PoopType(rawValue: typeRaw),
              let colorRaw = data["color"] as? String,
              let color = Log.PoopColor(rawValue: colorRaw),
              let sizeRaw = data["size"] as? String,
              let size = Log.PoopSize(rawValue: sizeRaw) else {
            throw AnalysisError.invalidResponse
        }

        let bloodPercentage = data["bloodPercentage"] as? Double ?? 0
        let hydrationPercentage = data["hydrationPercentage"] as? Double
        let fiberPercentage = data["fiberPercentage"] as? Double
        let analysis = data["analysis"] as? String ?? "Analysis complete."

        // Derive poop score from type
        let poopScore = Log.categorizePoopType(type)

        return AnalysisResult(
            type: type,
            color: color,
            size: size,
            poopScore: poopScore,
            bloodPercentage: bloodPercentage,
            hydrationPercentage: hydrationPercentage,
            fiberPercentage: fiberPercentage,
            analysis: analysis
        )
    }
}

// MARK: - Analysis Result

struct AnalysisResult {
    let type: Log.PoopType
    let color: Log.PoopColor
    let size: Log.PoopSize
    let poopScore: Log.PoopCategory
    let bloodPercentage: Double
    let hydrationPercentage: Double?
    let fiberPercentage: Double?
    let analysis: String

    /// Convert to a Log entry
    func toLog() -> Log {
        Log(
            poopScore: poopScore,
            type: type,
            color: color,
            size: size,
            bloodPercentage: bloodPercentage,
            hydrationPercentage: hydrationPercentage,
            fiberPercentage: fiberPercentage,
            timestamp: Date(),
            analysis: analysis
        )
    }
}

// MARK: - Errors

enum AnalysisError: LocalizedError {
    case invalidImage
    case invalidResponse
    case notStoolImage
    case functionError(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not process the image"
        case .invalidResponse:
            return "Invalid response from analysis"
        case .notStoolImage:
            return "That doesn't look like what we're looking for. Please take a photo of your stool for analysis."
        case .functionError(let message):
            return message
        }
    }
}
