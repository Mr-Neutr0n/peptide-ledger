import Testing
@testable import LabelOCR

#if canImport(Vision) && canImport(CoreGraphics) && canImport(CoreText)
import CoreGraphics
import CoreText
import Foundation

/// Runs the real Vision recognizer on a rendered label. This is the only test that proves the
/// photo path (image -> text -> candidate fields) rather than the parser alone.
@Suite("vision recognizer on a rendered label")
struct RecognizerTests {
    @Test("rendered vial label yields compound, mass, and lot candidates")
    @available(iOS 18, macOS 15, *)
    func rendersAndRecognizes() async throws {
        let image = try #require(Self.renderLabel(lines: [
            "BPC-157",
            "5 mg",
            "Lot A2291",
            "EXP 12/2027",
        ]))
        let result = try await LabelRecognizer().recognize(cgImage: image)
        #expect(result.text.localizedCaseInsensitiveContains("BPC"))
        #expect(result.candidate.massValue == 5)
        #expect(result.candidate.massUnit == "mg")
        #expect(result.candidate.lot?.uppercased().contains("A2291") == true)
        #expect(result.candidate.confidence > 0.5)
    }

    /// Black monospace text on white, large enough for Vision to read without a real camera.
    static func renderLabel(lines: [String]) -> CGImage? {
        let width = 900
        let height = 120 * lines.count + 80
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        let font = CTFontCreateWithName("Menlo-Bold" as CFString, 64, nil)
        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: CGColor(red: 0, green: 0, blue: 0, alpha: 1),
        ]
        for (index, line) in lines.enumerated() {
            let attributed = CFAttributedStringCreate(nil, line as CFString, attributes as CFDictionary)
            let ctLine = CTLineCreateWithAttributedString(attributed!)
            let y = CGFloat(height - 100 - index * 120)
            context.textPosition = CGPoint(x: 40, y: y)
            CTLineDraw(ctLine, context)
        }
        return context.makeImage()
    }
}
#endif
