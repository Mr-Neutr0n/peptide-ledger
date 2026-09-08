// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PeptideLedger",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(name: "DoseMath", targets: ["DoseMath"]),
        .library(name: "LedgerCore", targets: ["LedgerCore"]),
        .library(name: "ModelClient", targets: ["ModelClient"]),
        .library(name: "LabelOCR", targets: ["LabelOCR"]),
        .library(name: "Clerk", targets: ["Clerk"]),
    ],
    targets: [
        .target(name: "DoseMath"),
        .target(name: "LedgerCore", dependencies: ["DoseMath"]),
        .target(name: "ModelClient"),
        .target(name: "LabelOCR"),
        .target(
            name: "Clerk",
            dependencies: ["LedgerCore", "DoseMath", "ModelClient", "LabelOCR"]
        ),
        .testTarget(name: "DoseMathTests", dependencies: ["DoseMath"]),
        .testTarget(name: "LedgerCoreTests", dependencies: ["LedgerCore", "DoseMath"]),
        .testTarget(name: "ModelClientTests", dependencies: ["ModelClient"]),
        .testTarget(name: "LabelOCRTests", dependencies: ["LabelOCR"]),
        .testTarget(name: "ClerkTests", dependencies: ["Clerk", "LedgerCore", "DoseMath", "ModelClient"]),
        .testTarget(
            name: "EvalTests",
            dependencies: ["Clerk", "LedgerCore", "DoseMath", "ModelClient", "LabelOCR"]
        ),
    ]
)
