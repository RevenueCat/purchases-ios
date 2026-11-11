//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PerformanceBaseline.swift
//

import Foundation

struct PerformanceBaseline: Codable {
    var peakMemoryMiB: Double?
    var cpuInstructionsThousands: Double?
    var workloadSHA256: String
    var environment: [String: String]

    static let fileURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Baselines.json")

    static func checkOrRecordMemory(
        peakMemoryMiB: Double,
        tolerancePercent: Double,
        testName: String,
        workloadSHA256: String,
        environment: [String: String],
        record: Bool = false,
        fileURL: URL = Self.fileURL
    ) throws {
        var baselines = try self.load(from: fileURL)
        if record {
            baselines[testName] = Self(
                peakMemoryMiB: peakMemoryMiB,
                cpuInstructionsThousands: nil,
                workloadSHA256: workloadSHA256,
                environment: environment
            )
            try self.write(baselines, to: fileURL)
            print("Recorded \(testName): \(peakMemoryMiB) MiB in \(fileURL.path). Review the baseline diff.")
            return
        }
        guard let baseline = baselines[testName] else {
            throw Failure("No baseline for \(testName). Set RECORD_PERFORMANCE_BASELINES=1 to record it.")
        }
        guard let baselinePeakMemoryMiB = baseline.peakMemoryMiB else {
            throw Failure("\(testName): baseline does not contain peak memory.")
        }
        guard baseline.environment == environment else {
            throw Failure("\(testName): environment differs. Use the baseline simulator and Xcode version.")
        }
        guard baseline.workloadSHA256 == workloadSHA256 else {
            throw Failure("\(testName): workload differs. Review the change before you record a new baseline.")
        }
        let limit = baselinePeakMemoryMiB * (1 + tolerancePercent / 100)
        let values = String(format: "peak %.2f MiB, baseline %.2f MiB, limit %.2f MiB",
                            peakMemoryMiB, baselinePeakMemoryMiB, limit)
        guard peakMemoryMiB <= limit else { throw Failure("\(testName): \(values)") }
        print("PASS \(testName): \(values)")
    }

    static func checkOrRecordCPU(
        cpuInstructionsThousands: Double,
        tolerancePercent: Double,
        testName: String,
        workloadSHA256: String,
        environment: [String: String],
        record: Bool = false,
        fileURL: URL = Self.fileURL
    ) throws {
        var baselines = try self.load(from: fileURL)
        if record {
            baselines[testName] = Self(
                peakMemoryMiB: nil,
                cpuInstructionsThousands: cpuInstructionsThousands,
                workloadSHA256: workloadSHA256,
                environment: environment
            )
            try self.write(baselines, to: fileURL)
            print("Recorded \(testName): \(cpuInstructionsThousands) kI in \(fileURL.path). Review the baseline diff.")
            return
        }
        guard let baseline = baselines[testName] else {
            throw Failure("No baseline for \(testName). Set RECORD_PERFORMANCE_BASELINES=1 to record it.")
        }
        guard let baselineCPUInstructionsThousands = baseline.cpuInstructionsThousands else {
            throw Failure("\(testName): baseline does not contain CPU instructions.")
        }
        guard baseline.environment == environment else {
            throw Failure("\(testName): environment differs. Use the baseline simulator and Xcode version.")
        }
        guard baseline.workloadSHA256 == workloadSHA256 else {
            throw Failure("\(testName): workload differs. Review the change before you record a new baseline.")
        }
        let limit = baselineCPUInstructionsThousands * (1 + tolerancePercent / 100)
        let values = String(format: "CPU %.0f kI, baseline %.0f kI, limit %.0f kI",
                            cpuInstructionsThousands, baselineCPUInstructionsThousands, limit)
        guard cpuInstructionsThousands <= limit else { throw Failure("\(testName): \(values)") }
        print("PASS \(testName): \(values)")
    }

    private static func load(from fileURL: URL) throws -> [String: Self] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [:] }
        return try JSONDecoder().decode([String: Self].self, from: Data(contentsOf: fileURL))
    }

    private static func write(_ baselines: [String: Self], to fileURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try (encoder.encode(baselines) + Data([0x0a])).write(to: fileURL, options: .atomic)
    }

    struct Failure: Error, CustomStringConvertible {
        let description: String

        init(_ description: String) {
            self.description = description
        }
    }
}
