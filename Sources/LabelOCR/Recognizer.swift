import Foundation

#if canImport(Vision)
import Vision

@available(iOS 18, macOS 15, *)
public struct LabelRecognizer: Sendable {
    public init() {}

    public func recognize(cgImage: CGImage) async throws -> (text: String, candidate: LabelCandidate) {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let observations = try await request.perform(on: cgImage)
        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        let text = lines.joined(separator: "\n")
        return (text, LabelFieldParser.parse(text))
    }
}
#endif
