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
import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallStateStore: ObservableObject {

    private let lock = NSLock()
    private let eventQueue = DispatchQueue(label: "com.revenuecat.paywalls.state.events")
    private let slotRegistry: PaywallStateSlotRegistry
    private var values: [PaywallStateKey: PaywallStateValue?]
    private let resolvedEventsSubject = PassthroughSubject<
        PaywallStateChange.Event<PaywallStateChange.Committed>,
        Never
    >()

    init(
        initialValues: [PaywallStateKey: PaywallStateValue?] = [:],
        slotRegistry: PaywallStateSlotRegistry = .acceptingAll
    ) {
        self.slotRegistry = slotRegistry
        self.values = initialValues
    }

    var resolvedEvents: AnyPublisher<PaywallStateChange.Event<PaywallStateChange.Committed>, Never> {
        self.resolvedEventsSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func value(for key: PaywallStateKey) -> PaywallStateValue? {
        self.lock.lock()
        let value = self.values[key] ?? nil
        self.lock.unlock()
        return value
    }

    func publisher(for key: PaywallStateKey) -> AnyPublisher<PaywallStateValue?, Never> {
        Deferred { [weak self] in
            Just(self?.value(for: key) ?? nil)
                .append(
                    self?.resolvedEvents
                        .filter { $0.key == key }
                        .map(\.newValue)
                        .eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
                )
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func request(
        _ mutation: PaywallStateMutation,
        details: (any PaywallStateChange.Details)?,
        mutationHandler: PaywallStateMutationHandler? = nil
    ) {
        let proposedChange = PaywallStateChange.Event<PaywallStateChange.Proposed>(
            key: mutation.key,
            oldValue: self.value(for: mutation.key),
            newValue: mutation.value,
            details: details
        )

        guard let mutationHandler else {
            self.commit(mutation, details: details)
            return
        }

        let proposal = PaywallStateMutationProposal(change: proposedChange) { [weak self] resolution in
            switch resolution {
            case .accept:
                self?.commit(mutation, details: details)
            case .reject:
                break
            case .replace(let replacement):
                self?.commit(replacement, details: details)
            }
        }
        mutationHandler(proposal)
    }

    private func commit(_ mutation: PaywallStateMutation, details: (any PaywallStateChange.Details)?) {
        guard self.slotRegistry.accepts(mutation) else {
            Logger.warning("Ignoring invalid paywall state mutation for key '\(mutation.key.field.rawValue)'.")
            return
        }

        self.lock.lock()
        let result: PaywallStateChange.Event<PaywallStateChange.Committed>? = {
            let oldValue = self.values[mutation.key] ?? nil
            guard oldValue != mutation.value else { return nil }

            self.values[mutation.key] = mutation.value
            let change = PaywallStateChange.Event<PaywallStateChange.Committed>(
                key: mutation.key,
                oldValue: oldValue,
                newValue: mutation.value,
                details: details
            )
            return change
        }()
        self.lock.unlock()

        guard let result else { return }
        self.eventQueue.async {
            self.resolvedEventsSubject.send(result)
        }
    }

}

#endif
