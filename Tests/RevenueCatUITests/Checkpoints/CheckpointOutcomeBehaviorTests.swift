//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointOutcomeBehaviorTests.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) @testable import RevenueCat
@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) @testable import RevenueCatUI
import XCTest

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointOutcomeBehaviorTests: TestCase {

    // Unknown checkpoint: invoke the callback with nil and do not invoke the error presenter.
    func testUnknownCheckpoint() async {
        await self.assertCompletedWithNil(.noAction(.unknownCheckpoint))
    }

    // No matching rule: invoke the callback with nil and do not invoke the error presenter.
    func testNoMatchingRule() async {
        await self.assertCompletedWithNil(.noAction(.noMatch))
    }

    // Invalid checkpoint identifier: do not invoke the callback or the error presenter.
    func testInvalidCheckpointIdentifier() async {
        let errorPresenterCalls = CallCounter()
        let manager = CheckpointsManager { _, _ in
            XCTFail("Invalid identifiers must not reach resolution")
            return .noAction(.noMatch)
        }

        let result = await manager.checkpointForCallback(
            identifier: " checkout😀",
            params: self.params(errorPresenterCalls: errorPresenterCalls)
        )

        self.assertSuppressed(result)
        XCTAssertEqual(errorPresenterCalls.count, 0)
    }

    // Checkpoint resolution failure: do not invoke the callback or the error presenter.
    func testResolutionFailure() async {
        let errorPresenterCalls = CallCounter()
        let manager = CheckpointsManager { _, _ in
            throw NSError(domain: "CheckpointOutcomeBehaviorTests", code: 1)
        }

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: self.params(errorPresenterCalls: errorPresenterCalls)
        )

        self.assertSuppressed(result)
        XCTAssertEqual(errorPresenterCalls.count, 0)
    }

    // Configuration unavailable: do not invoke the callback or the error presenter.
    func testConfigurationUnavailable() async {
        let errorPresenterCalls = CallCounter()
        let manager = CheckpointsManager { _, _ in .noAction(.configurationUnavailable) }

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: self.params(errorPresenterCalls: errorPresenterCalls)
        )

        self.assertSuppressed(result)
        XCTAssertEqual(errorPresenterCalls.count, 0)
    }

    private func assertCompletedWithNil(
        _ resolution: CheckpointResolution,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let errorPresenterCalls = CallCounter()
        let manager = CheckpointsManager { _, _ in resolution }

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: self.params(errorPresenterCalls: errorPresenterCalls)
        )

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected the callback to be invoked", file: file, line: line)
        }
        XCTAssertNil(flowResult, file: file, line: line)
        XCTAssertEqual(errorPresenterCalls.count, 0, file: file, line: line)
    }

    private func assertSuppressed(
        _ result: CheckpointCallbackResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .suppressed = result else {
            return XCTFail("Expected the callback not to be invoked", file: file, line: line)
        }
    }

    private func params(errorPresenterCalls: CallCounter) -> CheckpointCallParams {
        return .init(errorPresenter: { _, _ in
            errorPresenterCalls.count += 1
        })
    }

}

private final class CallCounter: @unchecked Sendable {
    var count = 0
}
