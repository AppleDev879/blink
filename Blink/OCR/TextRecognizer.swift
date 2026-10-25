import AppKit
import Foundation
import Vision

enum TextRecognizerError: Error, LocalizedError {
    case noImage
    case visionFailed(String)
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .noImage: return "Nothing to read."
        case .visionFailed(let message): return message
        case .emptyResult: return "No text found."
        }
    }
}

/// Thin wrapper around `VNRecognizeTextRequest`.
final class TextRecognizer {
    var recognitionLevel: VNRequestTextRecognitionLevel = .accurate
    var usesLanguageCorrection = true
    var minimumConfidence: Float = 0.3

    func recognize(cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: TextRecognizerError.visionFailed(error.localizedDescription))
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: TextRecognizerError.emptyResult)
                    return
                }

                var items: [(text: String, confidence: Float, minY: CGFloat, minX: CGFloat)] = []
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    let box = observation.boundingBox
                    items.append((
                        text: candidate.string,
                        confidence: candidate.confidence,
                        minY: box.minY,
                        minX: box.minX
                    ))
                }

                let joined = OCRTextNormalizer.joinObservations(items, minimumConfidence: self.minimumConfidence)
                if joined.isEmpty {
                    continuation.resume(throwing: TextRecognizerError.emptyResult)
                } else {
                    continuation.resume(returning: joined)
                }
            }
            request.recognitionLevel = self.recognitionLevel
            request.usesLanguageCorrection = self.usesLanguageCorrection

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: TextRecognizerError.visionFailed(error.localizedDescription))
            }
        }
    }

    func recognize(nsImage: NSImage) async throws -> String {
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw TextRecognizerError.noImage
        }
        return try await recognize(cgImage: cgImage)
    }
}
