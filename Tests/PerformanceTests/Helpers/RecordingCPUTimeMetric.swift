//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RecordingCPUTimeMetric.swift
//
//  Created by Rick van der Linden on 11/11/26.

import XCTest

final class RecordingCPUTimeMetric: XCTCPUMetric {

    final class Samples {
        var cpuTimeSeconds: [Double] = []
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
        return RecordingCPUTimeMetric(
            samples: self.samples,
            limitingToCurrentThread: self.limitingToCurrentThread
        )
    }

    override func reportMeasurements(
        from startTime: XCTPerformanceMeasurementTimestamp,
        to endTime: XCTPerformanceMeasurementTimestamp
    ) throws -> [XCTPerformanceMeasurement] {
        let measurements = try super.reportMeasurements(from: startTime, to: endTime)
        let cpuTime = try XCTUnwrap(measurements.first {
            $0.identifier == "com.apple.dt.XCTMetric_CPU.time"
        })
        let cpuTimeSeconds: Double
        switch cpuTime.unitSymbol {
        case "s":
            cpuTimeSeconds = cpuTime.doubleValue
        case "ms":
            cpuTimeSeconds = cpuTime.doubleValue / 1_000
        case "µs", "us":
            cpuTimeSeconds = cpuTime.doubleValue / 1_000_000
        case "ns":
            cpuTimeSeconds = cpuTime.doubleValue / 1_000_000_000
        default:
            throw PerformanceBaseline.Failure("Unsupported CPU time unit: \(cpuTime.unitSymbol)")
        }
        guard cpuTimeSeconds > 0 else {
            throw PerformanceBaseline.Failure("CPU time measurement must be greater than zero.")
        }
        self.samples.cpuTimeSeconds.append(cpuTimeSeconds)
        return measurements
    }

}
