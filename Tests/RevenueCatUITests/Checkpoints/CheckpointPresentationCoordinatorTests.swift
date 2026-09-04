//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointPresentationCoordinatorTests.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) @testable import RevenueCat
@_spi(CheckpointsInternal) @_spi(Internal) @testable import RevenueCatUI
import XCTest

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointPresentationCoordinatorTests: TestCase {

    func testOnlyOnePresentationCanOwnTheSlot() async throws {
        let coordinator = CheckpointPresentationCoordinator(handler: MockCheckpointPresentationHandler())
        let started = self.expectation(description: "First presentation starts")
        var resumeFirst: CheckedContinuation<Void, Never>?
        let first = Task {
            try await coordinator.withPresentationSession { _ in
                started.fulfill()
                await withCheckedContinuation { continuation in
                    resumeFirst = continuation
                }
            }
        }

        await self.fulfillment(of: [started], timeout: 1)
        do {
            _ = try await coordinator.withPresentationSession { _ in () }
            XCTFail("Expected the second presentation to be rejected")
        } catch {
            XCTAssertEqual((error as NSError).code, ErrorCode.operationAlreadyInProgressForProductError.rawValue)
        }

        resumeFirst?.resume()
        _ = try await first.value
    }

    func testEachPresentationGetsItsOwnSession() async throws {
        let coordinator = CheckpointPresentationCoordinator(handler: MockCheckpointPresentationHandler())
        var firstSession: CheckpointPresentationCoordinator.Session?
        var secondSession: CheckpointPresentationCoordinator.Session?

        _ = try await coordinator.withPresentationSession { session in
            firstSession = session
        }
        _ = try await coordinator.withPresentationSession { session in
            secondSession = session
        }

        XCTAssertNotNil(firstSession)
        XCTAssertNotNil(secondSession)
        XCTAssertFalse(firstSession === secondSession)
    }

    func testSlotIsReleasedAfterOperationThrows() async throws {
        let coordinator = CheckpointPresentationCoordinator(handler: MockCheckpointPresentationHandler())
        let expectedError = NSError(domain: "test", code: 42)

        do {
            _ = try await coordinator.withPresentationSession { _ in
                throw expectedError
            }
            XCTFail("Expected the operation to throw")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }

        _ = try await coordinator.withPresentationSession { _ in () }
    }

    func testCancellingPresentationCancelsActiveSession() async throws {
        let coordinator = CheckpointPresentationCoordinator(handler: MockCheckpointPresentationHandler())
        let started = self.expectation(description: "Presentation starts")
        var resumePresentation: CheckedContinuation<Void, Error>?

        let presentation = Task {
            try await coordinator.withPresentationSession { session in
                started.fulfill()
                session.setCancellationHandler {
                    resumePresentation?.resume(throwing: CancellationError())
                    resumePresentation = nil
                }
                try await withCheckedThrowingContinuation { continuation in
                    resumePresentation = continuation
                }
            }
        }

        await self.fulfillment(of: [started], timeout: 1)
        presentation.cancel()

        do {
            _ = try await presentation.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected.
        }
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class MockCheckpointPresentationHandler: CheckpointPresentationHandler {

    func present(
        _: CheckpointPresentation,
        session _: CheckpointPresentationCoordinator.Session
    ) async throws -> CheckpointPaywallOutcome {
        return .Dismissed.shared
    }

}
