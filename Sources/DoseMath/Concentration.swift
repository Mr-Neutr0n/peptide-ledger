import Foundation

/// Mass per millilitre after reconstitution (or as labeled for an already-liquid vial).
public struct Concentration: Sendable, Hashable, Codable, Equatable, CustomStringConvertible {
    public var mass: Mass
    public var per: Volume

    public init(mass: Mass, per: Volume) {
        self.mass = mass
        self.per = per
    }

    public var microgramsPerMilliliter: Decimal {
        guard per.milliliters != 0 else { return 0 }
        return mass.micrograms / per.milliliters
    }

    public var milligramsPerMilliliter: Decimal {
        microgramsPerMilliliter / 1000
    }

    public var description: String {
        "\(DoseFormat.decimal(milligramsPerMilliliter)) mg/mL (\(DoseFormat.decimal(microgramsPerMilliliter)) mcg/mL)"
    }

    public static func reconstitute(mass: Mass, diluent: Volume) throws -> Concentration {
        try Sanity.requirePositive(mass.micrograms, name: "vial mass")
        try Sanity.requirePositive(diluent.milliliters, name: "diluent volume")
        return Concentration(mass: mass, per: diluent)
    }
}
