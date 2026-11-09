//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MemoryBaseline.swift
//

import Foundation

struct MemoryBaseline: Codable {
    var peakMemoryMiB: Double
    var workloadSHA256: String
    var environment: [String: String]

    static let fileURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Baselines.json")

    static func checkOrRecord(
        peakMemoryMiB: Double,
        tolerancePercent: Double,
        testName: String,
        workloadSHA256: String,
        environment: [String: String],
        record: Bool = false,
        fileURL: URL = Self.fileURL
    ) throws {
        var baselines: [String: Self] = [:]
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            baselines = try JSONDecoder().decode([String: Self].self, from: data)
        }
        if record {
            baselines[testName] = Self(
                peakMemoryMiB: peakMemoryMiB,
                workloadSHA256: workloadSHA256,
                environment: environment
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            try (encoder.encode(baselines) + Data([0x0a])).write(to: fileURL, options: .atomic)
            print("Recorded \(testName): \(peakMemoryMiB) MiB in \(fileURL.path). Review the baseline diff.")
            return
        }
        guard let baseline = baselines[testName] else {
            throw Failure("No baseline for \(testName). Set RECORD_PERFORMANCE_BASELINES=1 to record it.")
        }
        guard baseline.environment == environment else {
            throw Failure("\(testName): environment differs. Use the baseline simulator and Xcode version.")
        }
        guard baseline.workloadSHA256 == workloadSHA256 else {
            throw Failure("\(testName): workload differs. Review the change before you record a new baseline.")
        }
        let limit = baseline.peakMemoryMiB * (1 + tolerancePercent / 100)
        let values = String(format: "peak %.2f MiB, baseline %.2f MiB, limit %.2f MiB",
                            peakMemoryMiB, baseline.peakMemoryMiB, limit)
        guard peakMemoryMiB <= limit else { throw Failure("\(testName): \(values)") }
        print("PASS \(testName): \(values)")
    }

    struct Failure: Error, CustomStringConvertible {
        let description: String

        init(_ description: String) {
            self.description = description
        }
    }
}
