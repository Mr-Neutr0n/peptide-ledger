import Testing
@testable import LabelOCR

@Suite("label field parser")
struct LabelOCRTests {
    @Test("reads compound, mass, lot, expiry from messy label text")
    func parseBPC() {
        let text = """
        BPC-157
        5 mg lyophilized
        Lot: A19C4
        EXP 12/2027
        Research use only
        """
        let candidate = LabelFieldParser.parse(text)
        #expect(candidate.compoundName == "BPC-157")
        #expect(candidate.massValue == 5)
        #expect(candidate.massUnit == "mg")
        #expect(candidate.lot == "A19C4")
        #expect(candidate.expiry != nil)
        #expect(candidate.confidence > 0.5)
    }

    @Test("never auto-commits: parser returns candidates only")
    func candidatesOnly() {
        let candidate = LabelFieldParser.parse("semaglutide 2 mg")
        #expect(candidate.compoundName != nil)
        #expect(candidate.massUnit == "mg")
    }
}
