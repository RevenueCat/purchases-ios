//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RecordingCPUMetric.swift
//
//  Created by Rick van der Linden on 11/11/26.

import XCTest

final class RecordingCPUMetric: XCTCPUMetric {

    final class Samples {
        var cpuInstructionsThousands: [Double] = []
    }

    let samples: Samples
    private let limitingToCurrentThread: Bool

    override init(limitingToCurrentThread: Bool) {
        self.samples = Samples()
        self.limitingToCurrentThread = limitingToCurrentThread
        super.init(limitingToCurrentThread: limitingToCurrentThread)
    }

    private init(samples: Samples, limitingToCurrentThread: Bool) {
        self.samples = samples
        self.limitingToCurrentThread = limitingToCurrentThread
        super.init(limitingToCurrentThread: limitingToCurrentThread)
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        return RecordingCPUMetric(
            samples: self.samples,
            limitingToCurrentThread: self.limitingToCurrentThread
        )
    }

    override func reportMeasurements(
        from startTime: XCTPerformanceMeasurementTimestamp,
        to endTime: XCTPerformanceMeasurementTimestamp
    ) throws -> [XCTPerformanceMeasurement] {
        let measurements = try super.reportMeasurements(from: startTime, to: endTime)
        let cpuInstructions = try XCTUnwrap(measurements.first {
            $0.identifier == "com.apple.dt.XCTMetric_CPU.instructions_retired"
        })
        let cpuInstructionsThousands: Double
        switch cpuInstructions.unitSymbol {
        case "I":
            cpuInstructionsThousands = cpuInstructions.doubleValue / 1_000
        case "kI":
            cpuInstructionsThousands = cpuInstructions.doubleValue
        default:
            throw PerformanceBaseline.Failure("Unsupported CPU instructions unit: \(cpuInstructions.unitSymbol)")
        }
        self.samples.cpuInstructionsThousands.append(cpuInstructionsThousands)
        return measurements
    }

}
