//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointIdentifierValidatorTests.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) @testable import RevenueCat
@_spi(CheckpointsInternal) @_spi(Internal) @testable import RevenueCatUI
import XCTest

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointIdentifierValidatorTests: TestCase {

    func testValidCheckpointIdentifiersReachResolution() async throws {
        var resolvedIdentifiers: [String] = []
        let manager = CheckpointsManager { identifier, _ in
            resolvedIdentifiers.append(identifier)
            return .noAction(.noMatch)
        }
        let validIdentifiers = [
            "a",
            "Z",
            "checkout",
            "checkout_123",
            "checkout-complete",
            "a" + String(repeating: "1", count: 99)
        ]

        for identifier in validIdentifiers {
            _ = try await manager.checkpoint(identifier: identifier, params: .init())
        }

        XCTAssertEqual(resolvedIdentifiers, validIdentifiers)
    }

    func testInvalidCheckpointIdentifiersFailBeforeListenerOrResolution() async {
        var resolutionCount = 0
        let manager = CheckpointsManager { _, _ in
            resolutionCount += 1
            return .noAction(.noMatch)
        }
        let listener = CheckpointListenerRecorder()
        manager.listener = listener
        let invalidIdentifiers = [
            "",
            "1checkout",
            "_checkout",
            "-checkout",
            "check out",
            "check.out",
            "chéckout",
            "a" + String(repeating: "1", count: 100)
        ]

        for identifier in invalidIdentifiers {
            do {
                _ = try await manager.checkpoint(identifier: identifier, params: .init())
                XCTFail("Expected '\(identifier)' to be rejected")
            } catch let error as CheckpointError {
                guard case .invalidIdentifier(let rejectedIdentifier) = error else {
                    return XCTFail("Expected invalidIdentifier, got \(error)")
                }

                XCTAssertEqual(rejectedIdentifier, identifier)
                XCTAssertEqual(error.errorCode, ErrorCode.configurationError.rawValue)
            } catch {
                XCTFail("Expected CheckpointError, got \(error)")
            }
        }

        XCTAssertEqual(resolutionCount, 0)
        XCTAssertEqual(listener.eventCount, 0)
    }

    func testCompletionAPIForwardsInvalidIdentifierError() {
        let completion = self.expectation(description: "Checkpoint fails")
        var resolutionCount = 0
        let manager = CheckpointsManager { _, _ in
            resolutionCount += 1
            return .noAction(.noMatch)
        }

        manager.checkpoint(identifier: "invalid checkpoint", params: .init()) { result in
            guard case let .failure(error) = result else {
                return XCTFail("Expected invalid identifier error")
            }

            XCTAssertEqual(error.code, ErrorCode.configurationError.rawValue)
            XCTAssertEqual(resolutionCount, 0)
            completion.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class CheckpointListenerRecorder: CheckpointListener {

    private(set) var eventCount = 0

    func onCheckpointHit(_ checkpoint: CheckpointInfo) {
        self.eventCount += 1
    }

    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult) {
        self.eventCount += 1
    }

}
