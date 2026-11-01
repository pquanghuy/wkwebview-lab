// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "LabCore", products: [.library(name: "LabCore", targets: ["LabCore"])], targets: [.target(name: "LabCore"), .testTarget(name: "LabCoreTests", dependencies: ["LabCore"])])
