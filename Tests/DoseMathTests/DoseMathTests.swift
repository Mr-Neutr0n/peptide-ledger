import Testing
import Foundation
@testable import DoseMath

@Suite("DoseMath reconstitution and draw volume")
struct DoseMathTests {
    @Test("5 mg in 2 mL BAC is 2.5 mg/mL; 250 mcg is 0.1 mL / 10 U-100")
    func classicBPCStyleReconstitution() throws {
        let conc = try Concentration.reconstitute(
            mass: Mass(5, .milligram),
            diluent: Volume(milliliters: 2)
        )
        #expect(conc.milligramsPerMilliliter == Decimal(string: "2.5"))
        #expect(conc.microgramsPerMilliliter == 2500)
        let draw = try DrawVolume.compute(
            dose: Mass(250, .microgram),
            concentration: conc,
            scale: .u100,
            vialMass: Mass(5, .milligram),
            vialVolume: Volume(milliliters: 2)
        )
        #expect(draw.volume.milliliters == Decimal(string: "0.1"))
        #expect(draw.syringeUnits == 10)
        #expect(draw.flags.isEmpty)
        #expect(draw.formula.contains("0.1"))
        #expect(draw.inputs["dose"] == "250 mcg")
    }

    @Test("mg and mcg convert by exactly 1000")
    func massConversion() {
        #expect(Mass(5, .milligram).micrograms == 5000)
        #expect(Mass(250, .microgram).milligrams == Decimal(string: "0.25"))
        #expect(Mass(1, .milligram).converted(to: .microgram) == Mass(1000, .microgram))
    }

    @Test("U-50 and U-40 scale marks from the same millilitres")
    func syringeScales() throws {
        let conc = try Concentration.reconstitute(mass: Mass(5, .milligram), diluent: Volume(milliliters: 2))
        let dose = Mass(250, .microgram)
        let u100 = try DrawVolume.compute(dose: dose, concentration: conc, scale: .u100)
        let u50 = try DrawVolume.compute(dose: dose, concentration: conc, scale: .u50)
        let u40 = try DrawVolume.compute(dose: dose, concentration: conc, scale: .u40)
        #expect(u100.volume == u50.volume)
        #expect(u100.syringeUnits == 10)
        #expect(u50.syringeUnits == 5)
        #expect(u40.syringeUnits == 4)
    }

    @Test("dose equal to the whole vial flags a likely mg/mcg mixup")
    func doseEqualsVial() throws {
        let conc = try Concentration.reconstitute(mass: Mass(5, .milligram), diluent: Volume(milliliters: 2))
        let draw = try DrawVolume.compute(
            dose: Mass(5, .milligram),
            concentration: conc,
            vialMass: Mass(5, .milligram),
            vialVolume: Volume(milliliters: 2)
        )
        #expect(draw.flags.contains { $0.code == "dose_equals_entire_vial" })
        #expect(draw.volume.milliliters == 2)
        #expect(draw.syringeUnits == 200)
        #expect(draw.flags.contains { $0.code == "syringe_over_capacity" })
        #expect(draw.flags.contains { $0.code == "draw_over_one_ml" })
    }

    @Test("dose larger than vial mass flags")
    func doseExceedsVial() throws {
        let conc = try Concentration.reconstitute(mass: Mass(5, .milligram), diluent: Volume(milliliters: 2))
        let draw = try DrawVolume.compute(
            dose: Mass(10, .milligram),
            concentration: conc,
            vialMass: Mass(5, .milligram),
            vialVolume: Volume(milliliters: 2)
        )
        #expect(draw.flags.contains { $0.code == "dose_exceeds_vial_mass" })
        #expect(draw.flags.contains { $0.code == "draw_exceeds_vial_volume" })
    }

    @Test("exactly 1000x mg/mcg mismatch flags")
    func thousandX() throws {
        let conc = try Concentration.reconstitute(mass: Mass(5, .milligram), diluent: Volume(milliliters: 2))
        // 5 mcg vs 5 mg vial is 1000x the other way
        let tiny = try DrawVolume.compute(
            dose: Mass(5, .microgram),
            concentration: conc,
            vialMass: Mass(5, .milligram)
        )
        #expect(tiny.flags.contains { $0.code == "mg_mcg_1000x" })

        let huge = try DrawVolume.compute(
            dose: Mass(5, .milligram),
            concentration: try Concentration.reconstitute(mass: Mass(5, .microgram), diluent: Volume(milliliters: 2)),
            vialMass: Mass(5, .microgram)
        )
        #expect(huge.flags.contains { $0.code == "mg_mcg_1000x" } || huge.flags.contains { $0.code == "dose_exceeds_vial_mass" })
    }

    @Test("draw larger than vial volume flags")
    func drawExceedsVolume() throws {
        let conc = Concentration(mass: Mass(5, .milligram), per: Volume(milliliters: 1))
        let draw = try DrawVolume.compute(
            dose: Mass(10, .milligram),
            concentration: conc,
            vialMass: Mass(5, .milligram),
            vialVolume: Volume(milliliters: 1)
        )
        #expect(draw.flags.contains { $0.code == "draw_exceeds_vial_volume" })
    }

    @Test("more than 100 units on U-100 flags")
    func overOneHundredUnits() throws {
        let conc = try Concentration.reconstitute(mass: Mass(10, .milligram), diluent: Volume(milliliters: 2))
        let draw = try DrawVolume.compute(
            dose: Mass(6, .milligram),
            concentration: conc,
            scale: .u100,
            vialMass: Mass(10, .milligram),
            vialVolume: Volume(milliliters: 2)
        )
        #expect(draw.syringeUnits == 120)
        #expect(draw.flags.contains { $0.code == "syringe_over_capacity" })
    }

    @Test("IU to mass refuses without a compound-specific factor")
    func iuRefusal() {
        #expect(throws: DoseMathError.iuConversionRequiresCompoundSpecificFactor) {
            try IUConversion.toMass(iu: InternationalUnits(10), massPerIU: nil)
        }
    }

    @Test("IU to mass accepts only with an explicit factor")
    func iuWithFactor() throws {
        let mass = try IUConversion.toMass(
            iu: InternationalUnits(10),
            massPerIU: Mass(1, .microgram)
        )
        #expect(mass == Mass(10, .microgram))
    }

    @Test("zero and negative inputs throw")
    func nonPositive() {
        #expect(throws: DoseMathError.self) {
            try Concentration.reconstitute(mass: Mass(0, .milligram), diluent: Volume(milliliters: 2))
        }
        #expect(throws: DoseMathError.self) {
            try Concentration.reconstitute(mass: Mass(5, .milligram), diluent: Volume(milliliters: 0))
        }
        #expect(throws: DoseMathError.self) {
            try DrawVolume.compute(
                dose: Mass(-1, .microgram),
                concentration: Concentration(mass: Mass(5, .milligram), per: Volume(milliliters: 2))
            )
        }
    }

    @Test("remaining doses is remaining volume divided by draw volume")
    func remaining() throws {
        let left = try RemainingDoses.count(
            remaining: Volume(milliliters: 1.8),
            perDraw: Volume(milliliters: Decimal(string: "0.1")!)
        )
        #expect(left == 18)
        let after = RemainingDoses.remainingVolume(
            start: Volume(milliliters: 2),
            drawn: Volume(milliliters: Decimal(string: "0.2")!)
        )
        #expect(after.milliliters == Decimal(string: "1.8"))
    }

    @Test("formula echoes every input")
    func formulaShowsWork() throws {
        let conc = try Concentration.reconstitute(mass: Mass(10, .milligram), diluent: Volume(milliliters: 1))
        let draw = try DrawVolume.compute(dose: Mass(500, .microgram), concentration: conc)
        #expect(draw.formula.contains("10 mg"))
        #expect(draw.formula.contains("1 mL"))
        #expect(draw.formula.contains("500 mcg"))
        #expect(Set(draw.inputs.keys).isSuperset(of: ["dose", "concentration", "syringe_scale"]))
    }
}
