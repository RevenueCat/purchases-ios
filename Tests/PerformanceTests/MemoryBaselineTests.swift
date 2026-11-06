//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MemoryBaselineTests.swift
//

import XCTest

// swiftlint:disable:next xctestcase_superclass
final class MemoryBaselineTests: XCTestCase {

    private var fileURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: self.fileURL.path) {
            try FileManager.default.removeItem(at: self.fileURL)
        }
        try super.tearDownWithError()
    }

    func testComparisonUsesToleranceAndRejectsChangedInputs() throws {
        try Data("""
        {"Example/testMemory()": {
          "peakMemoryMiB": 100,
          "workloadSHA256": "workload", "environment": {"model": "simulator"}
        }}
        """.utf8).write(to: self.fileURL)

        XCTAssertNoThrow(try self.check(peak: 110))
        XCTAssertNoThrow(try self.check(peak: 80))
        XCTAssertNoThrow(try self.check(peak: 115, tolerancePercent: 20))
        XCTAssertThrowsError(try self.check(peak: 110, tolerancePercent: 5))
        XCTAssertThrowsError(try self.check(peak: 111)) { error in
            XCTAssertTrue(String(describing: error).contains("limit 110.00 MiB"))
        }
        XCTAssertThrowsError(try self.check(peak: 80, workload: "changed"))
        XCTAssertThrowsError(try self.check(peak: 80, model: "another simulator"))
        XCTAssertThrowsError(try self.check(peak: 80, test: "Missing/testMemory()"))
    }

    func testRecordCreatesFileAndPreservesOtherBaselines() throws {
        try self.check(peak: 100, record: true)
        try self.check(peak: 50, test: "Another/testMemory()", record: true)
        try self.check(peak: 200, workload: "changed", record: true)

        let data = try Data(contentsOf: self.fileURL)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: [String: Any]])
        XCTAssertEqual(json.count, 2)
        XCTAssertEqual(json["Example/testMemory()"]?["peakMemoryMiB"] as? Double, 200)
        XCTAssertEqual(json["Example/testMemory()"]?["workloadSHA256"] as? String, "changed")
        XCTAssertEqual(json["Another/testMemory()"]?["peakMemoryMiB"] as? Double, 50)
    }

    private func check(
        peak: Double,
        tolerancePercent: Double = 10,
        workload: String = "workload",
        model: String = "simulator",
        test: String = "Example/testMemory()",
        record: Bool = false
    ) throws {
        try MemoryBaseline.checkOrRecord(
            peakMemoryMiB: peak,
            tolerancePercent: tolerancePercent,
            testName: test,
            workloadSHA256: workload,
            environment: ["model": model],
            record: record,
            fileURL: self.fileURL
        )
    }
}
