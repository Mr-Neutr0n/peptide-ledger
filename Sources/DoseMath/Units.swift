import Foundation

/// Mass with an explicit unit. Conversions between mg and mcg are exact (x1000).
public struct Mass: Sendable, Hashable, Codable, Equatable, CustomStringConvertible {
    public var value: Decimal
    public var unit: MassUnit

    public init(value: Decimal, unit: MassUnit) {
        self.value = value
        self.unit = unit
    }

    public init(_ value: Decimal, _ unit: MassUnit) {
        self.init(value: value, unit: unit)
    }

    public var micrograms: Decimal {
        switch unit {
        case .microgram: return value
        case .milligram: return value * 1000
        }
    }

    public var milligrams: Decimal {
        switch unit {
        case .milligram: return value
        case .microgram: return value / 1000
        }
    }

    public func converted(to unit: MassUnit) -> Mass {
        switch unit {
        case .microgram: return Mass(micrograms, .microgram)
        case .milligram: return Mass(milligrams, .milligram)
        }
    }

    public var description: String {
        "\(DoseFormat.decimal(value)) \(unit.rawValue)"
    }
}

public enum MassUnit: String, Sendable, Codable, CaseIterable {
    case milligram = "mg"
    case microgram = "mcg"
}

/// Volume in millilitres. Syringe "units" are a display of this volume, not a separate dimension.
public struct Volume: Sendable, Hashable, Codable, Equatable, CustomStringConvertible {
    public var milliliters: Decimal

    public init(milliliters: Decimal) {
        self.milliliters = milliliters
    }

    public var description: String {
        "\(DoseFormat.decimal(milliliters)) mL"
    }
}

/// IU is potency. It is not a mass and is not convertible across compounds.
public struct InternationalUnits: Sendable, Hashable, Codable, Equatable, CustomStringConvertible {
    public var value: Decimal

    public init(_ value: Decimal) {
        self.value = value
    }

    public var description: String {
        "\(DoseFormat.decimal(value)) IU"
    }
}

/// U-100: 100 marks = 1 mL. U-50: 50 marks = 1 mL. U-40: 40 marks = 1 mL.
public enum SyringeScale: String, Sendable, Codable, CaseIterable {
    case u100 = "U-100"
    case u50 = "U-50"
    case u40 = "U-40"

    public var unitsPerMilliliter: Decimal {
        switch self {
        case .u100: return 100
        case .u50: return 50
        case .u40: return 40
        }
    }

    public var capacityUnits: Decimal {
        switch self {
        case .u100: return 100
        case .u50: return 50
        case .u40: return 40
        }
    }
}

public enum DoseMathError: Error, Sendable, Equatable, CustomStringConvertible {
    case nonPositive(String)
    case iuConversionRequiresCompoundSpecificFactor
    case missingInput(String)
    case divideByZero(String)

    public var description: String {
        switch self {
        case .nonPositive(let name):
            return "\(name) must be greater than zero"
        case .iuConversionRequiresCompoundSpecificFactor:
            return "IU is potency and is not convertible to mass unless the user supplies a compound-specific IU-to-mass factor"
        case .missingInput(let name):
            return "missing input: \(name)"
        case .divideByZero(let name):
            return "cannot divide by zero (\(name))"
        }
    }
}

public enum DoseFormat {
    public static func decimal(_ value: Decimal, maxFractionDigits: Int = 6) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.usesGroupingSeparator = false
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}
