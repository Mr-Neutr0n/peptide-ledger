import Foundation

public struct DrawResult: Sendable, Equatable, Codable {
    public var volume: Volume
    public var syringeUnits: Decimal
    public var scale: SyringeScale
    public var concentration: Concentration
    public var dose: Mass
    public var flags: [SanityFlag]
    /// Human-readable formula with every input echoed. Shown in the Tools screen.
    public var formula: String
    public var inputs: [String: String]

    public init(
        volume: Volume,
        syringeUnits: Decimal,
        scale: SyringeScale,
        concentration: Concentration,
        dose: Mass,
        flags: [SanityFlag],
        formula: String,
        inputs: [String: String]
    ) {
        self.volume = volume
        self.syringeUnits = syringeUnits
        self.scale = scale
        self.concentration = concentration
        self.dose = dose
        self.flags = flags
        self.formula = formula
        self.inputs = inputs
    }
}

public enum DrawVolume {
    /// Draw volume = dose mass / concentration. Syringe marks = mL * units-per-mL for the chosen scale.
    public static func compute(
        dose: Mass,
        concentration: Concentration,
        scale: SyringeScale = .u100,
        vialMass: Mass? = nil,
        vialVolume: Volume? = nil
    ) throws -> DrawResult {
        try Sanity.requirePositive(dose.micrograms, name: "dose mass")
        try Sanity.requirePositive(concentration.microgramsPerMilliliter, name: "concentration")
        let mcgPerMl = concentration.microgramsPerMilliliter
        let milliliters = dose.micrograms / mcgPerMl
        let units = milliliters * scale.unitsPerMilliliter
        let volume = Volume(milliliters: milliliters)
        let flags = Sanity.flags(
            vialMass: vialMass,
            vialVolume: vialVolume ?? concentration.per,
            doseMass: dose,
            draw: volume,
            syringeUnits: units,
            scale: scale
        )
        let inputs: [String: String] = [
            "dose": dose.description,
            "concentration": concentration.description,
            "vial_mass": vialMass?.description ?? "(not supplied)",
            "vial_volume": (vialVolume ?? concentration.per).description,
            "syringe_scale": scale.rawValue,
            "units_per_mL": DoseFormat.decimal(scale.unitsPerMilliliter),
        ]
        let formula = """
        concentration = \(concentration.mass) / \(concentration.per) = \(concentration)
        draw mL = dose / concentration = \(dose) / \(concentration) = \(volume)
        \(scale.rawValue) marks = mL × \(DoseFormat.decimal(scale.unitsPerMilliliter)) = \(DoseFormat.decimal(units))
        """
        return DrawResult(
            volume: volume,
            syringeUnits: units,
            scale: scale,
            concentration: concentration,
            dose: dose,
            flags: flags,
            formula: formula,
            inputs: inputs
        )
    }
}

public enum RemainingDoses {
    public static func count(remaining: Volume, perDraw: Volume) throws -> Decimal {
        try Sanity.requirePositive(perDraw.milliliters, name: "draw volume")
        if remaining.milliliters < 0 {
            throw DoseMathError.nonPositive("remaining volume")
        }
        if remaining.milliliters == 0 {
            return 0
        }
        return remaining.milliliters / perDraw.milliliters
    }

    public static func remainingVolume(start: Volume, drawn: Volume) -> Volume {
        Volume(milliliters: start.milliliters - drawn.milliliters)
    }
}

public enum IUConversion {
    /// Refuses unless the caller supplies a compound-specific factor (mass per IU).
    public static func toMass(iu: InternationalUnits, massPerIU: Mass?) throws -> Mass {
        guard let massPerIU else {
            throw DoseMathError.iuConversionRequiresCompoundSpecificFactor
        }
        try Sanity.requirePositive(iu.value, name: "IU")
        try Sanity.requirePositive(massPerIU.micrograms, name: "mass per IU")
        return Mass(iu.value * massPerIU.micrograms, .microgram).converted(to: massPerIU.unit)
    }
}
