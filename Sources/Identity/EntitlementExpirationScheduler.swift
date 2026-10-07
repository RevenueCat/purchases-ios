//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EntitlementExpirationScheduler.swift
//

import Foundation

/// Async sleep abstraction used by ``EntitlementExpirationScheduler``.
/// Production wiring is ``EntitlementExpirationScheduler/TaskSleeper``.
protocol EntitlementExpirationSleeper: Sendable {
    func sleep(seconds: TimeInterval) async throws
}

/// Watches the active entitlements of the most recent `CustomerInfo` and reports the moment
/// their `expirationDate` passes according to the device clock.
///
/// The scheduler is purely local: it never touches the network. It arms a single sleeping `Task`
/// for the earliest future expiration, re-evaluates when it wakes, and reports every entitlement
/// whose expiration is already in the past. Each `(identifier, expirationDate)` pair is reported at
/// most once; a newer `CustomerInfo` with a different `expirationDate` for the same entitlement
/// re-enables it.
///
/// `Task.sleep` does not reliably advance while the process is suspended, so callers must
/// ``rearm()`` on foreground to catch expirations that happened while backgrounded.
final class EntitlementExpirationScheduler {

    typealias ExpirationHandler = @Sendable (_ appUserID: String, _ identifiers: [String]) -> Void

    fileprivate struct Key: Hashable {
        let identifier: String
        let expirationDate: Date
    }

    fileprivate struct State {
        var appUserID: String?
        var customerInfo: CustomerInfo?
        var notified: Set<Key> = []
        var task: Task<Void, Never>?
        var handler: ExpirationHandler?
    }

    private let sleeper: EntitlementExpirationSleeper
    private let dateProvider: DateProvider
    private let state: Atomic<State> = .init(.init())

    init(sleeper: EntitlementExpirationSleeper = TaskSleeper(),
         dateProvider: DateProvider = DateProvider()) {
        self.sleeper = sleeper
        self.dateProvider = dateProvider
    }

    deinit {
        self.state.value.task?.cancel()
    }

    /// Invoked off the lock, on an arbitrary thread, with the identifiers that just expired.
    var handler: ExpirationHandler? {
        get { self.state.value.handler }
        set { self.state.modify { $0.handler = newValue } }
    }

    /// Replaces the tracked `CustomerInfo` and re-evaluates. Switching `appUserID` forgets
    /// everything reported for the previous user.
    func arm(with customerInfo: CustomerInfo, appUserID: String) {
        self.evaluate { state in
            if state.appUserID != appUserID {
                state.notified = []
            }
            state.appUserID = appUserID
            state.customerInfo = customerInfo
        }
    }

    /// Re-evaluates against the wall clock using the last tracked `CustomerInfo`.
    func rearm() {
        self.evaluate { _ in }
    }

    func reset() {
        self.state.modify {
            $0.task?.cancel()
            $0 = .init(handler: $0.handler)
        }
    }

    // Visible for tests
    var isArmed: Bool { self.state.value.task != nil }

}

private extension EntitlementExpirationScheduler {

    func evaluate(_ update: (inout State) -> Void) {
        typealias Fired = (handler: ExpirationHandler, appUserID: String, identifiers: [String])
        let now = self.dateProvider.now()

        let fired: Fired? = self.state.modify { state in
            state.task?.cancel()
            state.task = nil
            update(&state)

            guard let appUserID = state.appUserID, let customerInfo = state.customerInfo else { return nil }

            let keys = Set(customerInfo.entitlements.active.compactMap { identifier, entitlement in
                entitlement.expirationDate.map { Key(identifier: identifier, expirationDate: $0) }
            })
            state.notified.formIntersection(keys)

            let due = keys.filter { $0.expirationDate <= now && !state.notified.contains($0) }
            state.notified.formUnion(due)

            if let next = keys.lazy.map(\.expirationDate).filter({ $0 > now }).min() {
                Logger.verbose(Strings.customerInfo.entitlement_expiration_scheduled(date: next))
                state.task = self.makeTask(firingAt: next, from: now)
            }

            guard !due.isEmpty, let handler = state.handler else { return nil }
            return (handler, appUserID, due.map(\.identifier).sorted())
        }

        if let fired {
            Logger.debug(Strings.customerInfo.entitlements_reached_expiration(identifiers: fired.identifiers))
            fired.handler(fired.appUserID, fired.identifiers)
        }
    }

    func makeTask(firingAt date: Date, from now: Date) -> Task<Void, Never> {
        return Task { [weak self, sleeper] in
            try? await sleeper.sleep(seconds: date.timeIntervalSince(now))
            guard !Task.isCancelled else { return }
            self?.rearm()
        }
    }

}

extension EntitlementExpirationScheduler {

    struct TaskSleeper: EntitlementExpirationSleeper {

        func sleep(seconds: TimeInterval) async throws {
            try await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
        }

    }

}

// @unchecked because all mutable state lives in `Atomic`.
extension EntitlementExpirationScheduler: @unchecked Sendable {}
