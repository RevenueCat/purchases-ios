//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Combine
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallStateStoreTests: TestCase {

    private var cancellables: Set<AnyCancellable> = []

    func testRequestWithoutGateCommitsImmediately() {
        let key = Self.makeKey(field: .component("visible"))
        let store = PaywallStateStore(initialValues: [key: .bool(true)])
        var events: [PaywallStateChange.Event<PaywallStateChange.Committed>] = []
        let eventExpectation = self.expectation(description: "committed event")
        store.resolvedEvents.sink {
            events.append($0)
            eventExpectation.fulfill()
        }.store(in: &cancellables)

        store.request(.init(key: key, value: .bool(false)), details: TestStateChangeDetails(source: "test"))

        self.wait(for: [eventExpectation], timeout: 1)
        XCTAssertEqual(store.value(for: key), .bool(false))
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.oldValue, .bool(true))
        XCTAssertEqual(events.first?.newValue, .bool(false))
        XCTAssertEqual((events.first?.details as? TestStateChangeDetails)?.source, "test")
    }

    func testGateCanRejectMutation() {
        let key = Self.makeKey(field: .component("visible"))
        let store = PaywallStateStore(initialValues: [key: .bool(true)])
        let handler = PaywallStateMutationHandler { proposal in
            proposal.reject()
        }

        store.request(
            .init(key: key, value: .bool(false)),
            details: TestStateChangeDetails(source: "test"),
            mutationHandler: handler
        )

        XCTAssertEqual(store.value(for: key), .bool(true))
    }

    func testGateCanReplaceMutationAndUsesReplacementOldValue() {
        let originalKey = Self.makeKey(field: .component("visible"))
        let replacementKey = Self.makeKey(field: .component("text"))
        let store = PaywallStateStore(initialValues: [
            originalKey: .bool(true),
            replacementKey: .string("old")
        ])
        var events: [PaywallStateChange.Event<PaywallStateChange.Committed>] = []
        let eventExpectation = self.expectation(description: "committed replacement event")
        store.resolvedEvents.sink {
            events.append($0)
            eventExpectation.fulfill()
        }.store(in: &cancellables)
        let handler = PaywallStateMutationHandler { proposal in
            XCTAssertEqual(proposal.change.key, originalKey)
            proposal.replace(with: .init(key: replacementKey, value: .string("new")))
        }

        store.request(
            .init(key: originalKey, value: .bool(false)),
            details: TestStateChangeDetails(source: "test"),
            mutationHandler: handler
        )

        self.wait(for: [eventExpectation], timeout: 1)
        XCTAssertEqual(store.value(for: originalKey), .bool(true))
        XCTAssertEqual(store.value(for: replacementKey), .string("new"))
        XCTAssertEqual(events.first?.key, replacementKey)
        XCTAssertEqual(events.first?.oldValue, .string("old"))
        XCTAssertEqual(events.first?.newValue, .string("new"))
    }

    func testProposalCanResolveOnlyOnce() {
        let key = Self.makeKey(field: .component("visible"))
        let store = PaywallStateStore(initialValues: [key: .bool(true)])
        let handler = PaywallStateMutationHandler { proposal in
            proposal.accept()
            proposal.reject()
            proposal.replace(with: .init(key: key, value: .bool(true)))
        }

        store.request(
            .init(key: key, value: .bool(false)),
            details: TestStateChangeDetails(source: "test"),
            mutationHandler: handler
        )

        XCTAssertEqual(store.value(for: key), .bool(false))
    }

    func testRejectsReplacementWithWrongValueKind() {
        let key = Self.makeKey(field: .component("visible"))
        var registry = PaywallStateSlotRegistry()
        registry.register(key, kind: .bool)
        let store = PaywallStateStore(initialValues: [key: .bool(true)], slotRegistry: registry)
        let handler = PaywallStateMutationHandler { proposal in
            proposal.replace(with: .init(key: key, value: .string("not a bool")))
        }

        store.request(
            .init(key: key, value: .bool(false)),
            details: TestStateChangeDetails(source: "test"),
            mutationHandler: handler
        )

        XCTAssertEqual(store.value(for: key), .bool(true))
    }

    private static func makeKey(field: PaywallStateKey.Field) -> PaywallStateKey {
        let scope = PaywallStateScope(
            instanceID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            paywallID: "paywall_a",
            offeringIdentifier: "default",
            paywallRevision: 1,
            workflowPageID: nil
        )
        return .init(
            scope: scope,
            component: .init(
                paywallID: "paywall_a",
                componentID: "component_a",
                type: "text",
                name: nil
            ),
            field: field
        )
    }

}

private struct TestStateChangeDetails: PaywallStateChange.Details {
    let source: String
}

#endif
