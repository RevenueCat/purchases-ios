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

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallStateStore: ObservableObject {

    private let lock = NSLock()
    private let eventQueue = DispatchQueue(label: "com.revenuecat.paywalls.state.events")
    private let slotRegistry: PaywallStateSlotRegistry
    private var values: [PaywallStateKey: PaywallStateValue?]
    private var subjects: [PaywallStateKey: CurrentValueSubject<PaywallStateValue?, Never>]
    private let resolvedEventsSubject = PassthroughSubject<
        PaywallStateChange.Event<PaywallStateChange.Committed>,
        Never
    >()

    init(
        initialValues: [PaywallStateKey: PaywallStateValue?] = [:],
        slotRegistry: PaywallStateSlotRegistry = .acceptingAllForTests
    ) {
        self.slotRegistry = slotRegistry
        self.values = initialValues
        self.subjects = initialValues.mapValues { CurrentValueSubject<PaywallStateValue?, Never>($0) }
    }

    var resolvedEvents: AnyPublisher<PaywallStateChange.Event<PaywallStateChange.Committed>, Never> {
        self.resolvedEventsSubject.eraseToAnyPublisher()
    }

    func value(for key: PaywallStateKey) -> PaywallStateValue? {
        self.lock.lock()
        let value = self.values[key] ?? nil
        self.lock.unlock()
        return value
    }

    func publisher(for key: PaywallStateKey) -> AnyPublisher<PaywallStateValue?, Never> {
        self.subject(for: key).eraseToAnyPublisher()
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
            return
        }

        self.lock.lock()
        let result: (
            subject: CurrentValueSubject<PaywallStateValue?, Never>,
            change: PaywallStateChange.Event<PaywallStateChange.Committed>
        )? = {
            let oldValue = self.values[mutation.key] ?? nil
            guard oldValue != mutation.value else { return nil }

            self.values[mutation.key] = mutation.value
            let subject = self.subjectLocked(for: mutation.key)
            let change = PaywallStateChange.Event<PaywallStateChange.Committed>(
                key: mutation.key,
                oldValue: oldValue,
                newValue: mutation.value,
                details: details
            )
            return (subject, change)
        }()
        self.lock.unlock()

        guard let result else { return }
        self.eventQueue.async {
            result.subject.send(mutation.value)
            self.resolvedEventsSubject.send(result.change)
        }
    }

    private func subject(for key: PaywallStateKey) -> CurrentValueSubject<PaywallStateValue?, Never> {
        self.lock.lock()
        let subject = self.subjectLocked(for: key)
        self.lock.unlock()
        return subject
    }

    private func subjectLocked(for key: PaywallStateKey) -> CurrentValueSubject<PaywallStateValue?, Never> {
        if let subject = self.subjects[key] {
            return subject
        }
        let subject = CurrentValueSubject<PaywallStateValue?, Never>(self.values[key] ?? nil)
        self.subjects[key] = subject
        return subject
    }

}

#endif
