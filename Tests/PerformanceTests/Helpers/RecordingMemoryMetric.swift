//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RecordingMemoryMetric.swift
//

import XCTest

final class RecordingMemoryMetric: XCTMemoryMetric {

    final class Samples {
        var peaksMiB: [Double] = []
    }

    let samples: Samples

    init(samples: Samples = Samples()) {
        self.samples = samples
        super.init()
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        return RecordingMemoryMetric(samples: self.samples)
    }

    override func reportMeasurements(
        from startTime: XCTPerformanceMeasurementTimestamp,
        to endTime: XCTPerformanceMeasurementTimestamp
    ) throws -> [XCTPerformanceMeasurement] {
        let measurements = try super.reportMeasurements(from: startTime, to: endTime)
        let peak = try XCTUnwrap(measurements.first {
            $0.identifier == "com.apple.dt.XCTMetric_Memory.physical_peak"
        })
        guard peak.unitSymbol == "byte" else {
            throw PerformanceBaseline.Failure("Unsupported memory unit: \(peak.unitSymbol)")
        }
        self.samples.peaksMiB.append(peak.doubleValue / 1_048_576)
        return measurements
    }
}
