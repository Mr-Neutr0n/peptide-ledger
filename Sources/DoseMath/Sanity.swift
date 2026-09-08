import Foundation

public struct SanityFlag: Sendable, Hashable, Codable, Equatable, CustomStringConvertible {
    public var code: String
    public var message: String

    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }

    public var description: String { "[\(code)] \(message)" }
}

public enum Sanity {
    public static func requirePositive(_ value: Decimal, name: String) throws {
        if value <= 0 {
            throw DoseMathError.nonPositive(name)
        }
    }

    /// Flags that look like the classic reconstitution mistakes. Never silently "fix" the numbers.
    public static func flags(
        vialMass: Mass?,
        vialVolume: Volume?,
        doseMass: Mass?,
        draw: Volume?,
        syringeUnits: Decimal?,
        scale: SyringeScale?
    ) -> [SanityFlag] {
        var flags: [SanityFlag] = []

        if let vialMass, let doseMass {
            let vialMcg = vialMass.micrograms
            let doseMcg = doseMass.micrograms
            if doseMcg > vialMcg {
                flags.append(SanityFlag(
                    code: "dose_exceeds_vial_mass",
                    message: "Dose \(doseMass) is larger than the entire vial mass \(vialMass)."
                ))
            }
            if doseMcg == vialMcg {
                flags.append(SanityFlag(
                    code: "dose_equals_entire_vial",
                    message: "Dose equals the entire labeled vial mass. That is usually a mg/mcg mixup (a 5 mg vial is not a 5 mg dose)."
                ))
            }
            if vialMcg > 0, doseMcg >= vialMcg * 100, doseMcg != vialMcg {
                flags.append(SanityFlag(
                    code: "dose_far_above_vial",
                    message: "Dose is at least 100x the labeled vial mass. Check mg vs mcg."
                ))
            }
            // 1000x: user treated mg as mcg or the reverse.
            if vialMcg > 0 {
                let ratio = doseMcg / vialMcg
                if ratio == 1000 || ratio == Decimal(1) / 1000 {
                    flags.append(SanityFlag(
                        code: "mg_mcg_1000x",
                        message: "Dose and vial mass differ by exactly 1000x, the mg/mcg conversion. Confirm which unit was on the label."
                    ))
                }
            }
        }

        if let vialVolume, let draw {
            if draw.milliliters > vialVolume.milliliters {
                flags.append(SanityFlag(
                    code: "draw_exceeds_vial_volume",
                    message: "Draw volume \(draw) is larger than the vial volume \(vialVolume)."
                ))
            }
        }

        if let syringeUnits, let scale, syringeUnits > scale.capacityUnits {
            flags.append(SanityFlag(
                code: "syringe_over_capacity",
                message: "\(DoseFormat.decimal(syringeUnits)) marks exceeds a \(scale.rawValue) syringe (max \(DoseFormat.decimal(scale.capacityUnits)))."
            ))
        }

        if let draw, draw.milliliters > 1, scale == .u100 || scale == nil {
            flags.append(SanityFlag(
                code: "draw_over_one_ml",
                message: "Draw volume \(draw) is more than 1 mL, which is more than one U-100 syringe."
            ))
        }

        return flags
    }
}
