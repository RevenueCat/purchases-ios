//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckoutPoller.swift
//
//  Created by Antonio Pallares on 22/9/26.

import Foundation

/// What became of a checkout session the customer was sent to.
@_spi(Internal) public enum HostedCheckoutPollResult: Equatable, Sendable {

    /// The purchase is on the customer's account.
    case succeeded

    /// The customer already owns what the checkout would have sold them.
    case alreadyPurchased

    /// The backend says the session ended without a purchase. `code` and `message` are the backend's own,
    /// absent where it gives no detail, and tell a declined payment from a checkout that never got going.
    case failed(code: Int?, message: String?)

    /// No answer either way, because the session was still under way when the attempts ran out or
    /// because it could not be asked about at all. Says nothing about whether a purchase happened.
    case undetermined

    /// The customer dismissed the checkout without paying.
    case abandoned

}

/// Asks the backend what became of a checkout session, one attempt at a time.
internal protocol HostedCheckoutPolling: Sendable {

    /// - Parameter appUserID: The customer the session belongs to, which every attempt asks about. The
    /// backend answers for no one else, so a poll that followed the current customer instead would stop
    /// answering the moment they changed.
    func poll(operationSessionID: String, appUserID: String) async -> HostedCheckoutPollResult

    /// Settles a checkout the customer dismissed before it sent them anywhere, where nothing says whether
    /// they paid: asks the payment provider once, and only polls if a payment is under way.
    func pollDismissed(operationSessionID: String, appUserID: String) async -> HostedCheckoutPollResult

}

/// Production wiring is ``HostedCheckoutPoller/WebBillingStatusFetcher``.
internal protocol HostedCheckoutStatusFetching: Sendable {

    func fetchStatus(operationSessionID: String,
                     appUserID: String) async -> Result<HostedCheckoutStatusResponse, BackendError>

    func fetchPaymentStatus(operationSessionID: String,
                            appUserID: String) async -> Result<HostedCheckoutPaymentStatusResponse, BackendError>

}

/// Async sleep abstraction used by the polling loop. Production wiring is ``HostedCheckoutPoller/TaskSleeper``.
internal protocol HostedCheckoutAsyncSleeper: Sendable {

    func sleep(seconds: TimeInterval) async throws

}

/// Bounded polling loop over the state of a checkout session.
///
/// Keeps asking while the session is under way, and while the backend fails in ways that tend to pass
/// (``BackendError/isTransient``). Only a session the backend calls failed comes back as
/// ``HostedCheckoutPollResult/failed``: everything else that stops the loop early is an answer the SDK does
/// not have, not a purchase that did not happen.
///
/// The bound is safe because asynchronous payment methods, which settle long after the customer leaves the
/// page, are deliberately unsupported.
///
/// Attempts alone do not bound how long the customer waits, since each one lasts as long as its request does.
/// So the loop gives up once ``timeout`` has passed, including on a request still out at that point.
internal struct HostedCheckoutPoller: HostedCheckoutPolling {

    /// Thirty attempts a second apart, matching `purchases-js`.
    static let defaultMaxAttempts = 30
    static let defaultInterval: TimeInterval = 1
    /// Leaves room for thirty attempts on a healthy connection.
    static let defaultTimeout: TimeInterval = 45

    private let statusFetcher: HostedCheckoutStatusFetching
    private let sleeper: HostedCheckoutAsyncSleeper
    private let dateProvider: DateProvider
    private let interval: TimeInterval
    let maxAttempts: Int
    let timeout: TimeInterval

    init(statusFetcher: HostedCheckoutStatusFetching,
         sleeper: HostedCheckoutAsyncSleeper,
         dateProvider: DateProvider,
         interval: TimeInterval,
         maxAttempts: Int,
         timeout: TimeInterval) {
        self.statusFetcher = statusFetcher
        self.sleeper = sleeper
        self.dateProvider = dateProvider
        self.interval = interval
        self.maxAttempts = maxAttempts
        self.timeout = timeout
    }

    static func makeDefault(webBillingAPI: WebBillingAPI) -> HostedCheckoutPoller {
        return .init(
            statusFetcher: WebBillingStatusFetcher(webBillingAPI: webBillingAPI),
            sleeper: TaskSleeper(),
            dateProvider: DateProvider(),
            interval: Self.defaultInterval,
            maxAttempts: Self.defaultMaxAttempts,
            timeout: Self.defaultTimeout
        )
    }

    func poll(operationSessionID: String, appUserID: String) async -> HostedCheckoutPollResult {
        return await self.poll(operationSessionID: operationSessionID,
                               appUserID: appUserID,
                               deadline: self.dateProvider.now().addingTimeInterval(self.timeout))
    }

    /// Asking whether the customer paid shares ``timeout`` with the polling it may lead to, so a dismissed
    /// sheet keeps the customer waiting no longer than a completed one.
    func pollDismissed(operationSessionID: String, appUserID: String) async -> HostedCheckoutPollResult {
        let deadline = self.dateProvider.now().addingTimeInterval(self.timeout)

        switch await self.paymentStatus(operationSessionID: operationSessionID,
                                        appUserID: appUserID,
                                        deadline: deadline) {
        case .notPaid:
            Logger.debug(Strings.hostedCheckout.dismissed_without_paying(operationSessionID))
            return .abandoned
        case .paying:
            return await self.poll(operationSessionID: operationSessionID, appUserID: appUserID, deadline: deadline)
        case .noAnswer:
            Logger.warn(Strings.hostedCheckout.payment_status_undetermined(operationSessionID))
            return .undetermined
        }
    }

}

private extension HostedCheckoutPoller {

    func poll(operationSessionID: String, appUserID: String, deadline: Date) async -> HostedCheckoutPollResult {
        Logger.debug(Strings.hostedCheckout.poll_start(operationSessionID, maxAttempts: self.maxAttempts))

        for attempt in 0..<self.maxAttempts {
            if Task.isCancelled {
                Logger.debug(Strings.hostedCheckout.poll_cancelled(operationSessionID))
                return .undetermined
            }

            if attempt > 0 {
                try? await self.sleeper.sleep(seconds: self.interval)
            }

            guard self.dateProvider.now() < deadline else {
                Logger.warn(Strings.hostedCheckout.poll_timed_out(operationSessionID, timeout: self.timeout))
                return .undetermined
            }

            switch await self.pollOnce(operationSessionID: operationSessionID,
                                       appUserID: appUserID,
                                       deadline: deadline) {
            case let .finished(result):
                return result
            case .retry:
                continue
            }
        }

        Logger.warn(Strings.hostedCheckout.poll_exhausted(operationSessionID, maxAttempts: self.maxAttempts))
        return .undetermined
    }

    /// A single attempt: either an answer to stop on, or a reason to ask again.
    enum PollAttemptResult {
        case finished(HostedCheckoutPollResult)
        case retry
    }

    enum PaymentStatusAnswer {
        case notPaid
        case paying
        case noAnswer
    }

    /// Asking the payment provider is costly for the backend, so an unknown answer, or an error that tends
    /// to pass, is asked about only once more.
    static let paymentStatusAttempts = 2

    func paymentStatus(operationSessionID: String, appUserID: String, deadline: Date) async -> PaymentStatusAnswer {
        let statusFetcher = self.statusFetcher

        for attempt in 0..<Self.paymentStatusAttempts {
            if Task.isCancelled {
                Logger.debug(Strings.hostedCheckout.poll_cancelled(operationSessionID))
                return .noAnswer
            }

            if attempt > 0 {
                try? await self.sleeper.sleep(seconds: self.interval)
            }

            guard self.dateProvider.now() < deadline,
                  let fetched = await self.value(before: deadline, of: {
                      await statusFetcher.fetchPaymentStatus(operationSessionID: operationSessionID,
                                                             appUserID: appUserID)
                  }) else {
                Logger.warn(Strings.hostedCheckout.poll_timed_out(operationSessionID, timeout: self.timeout))
                return .noAnswer
            }

            switch fetched {
            case let .success(response):
                switch response.paymentStatus {
                case .open:
                    return .notPaid
                case .processing:
                    return .paying
                case .unknown:
                    Logger.debug(Strings.hostedCheckout.payment_status_unknown(operationSessionID))
                }

            case let .failure(error) where error.isTransient:
                Logger.verbose(Strings.hostedCheckout.poll_transient_error(operationSessionID, error: error))

            case let .failure(error):
                Logger.error(Strings.hostedCheckout.poll_terminal_error(operationSessionID, error: error))
                return .noAnswer
            }
        }

        return .noAnswer
    }

    func pollOnce(operationSessionID: String, appUserID: String, deadline: Date) async -> PollAttemptResult {
        let statusFetcher = self.statusFetcher
        guard let fetched = await self.value(before: deadline, of: {
            await statusFetcher.fetchStatus(operationSessionID: operationSessionID, appUserID: appUserID)
        }) else {
            Logger.warn(Strings.hostedCheckout.poll_timed_out(operationSessionID, timeout: self.timeout))
            return .finished(.undetermined)
        }

        switch fetched {
        case let .success(response):
            return self.result(for: response.status, operationSessionID: operationSessionID)

        case let .failure(error) where error.isTransient:
            Logger.verbose(Strings.hostedCheckout.poll_transient_error(operationSessionID, error: error))
            return .retry

        case let .failure(error):
            Logger.error(Strings.hostedCheckout.poll_terminal_error(operationSessionID, error: error))
            return .finished(.undetermined)
        }
    }

    func result(for status: HostedCheckoutStatusResponse.Status,
                operationSessionID: String) -> PollAttemptResult {
        switch status {
        case .succeeded:
            Logger.debug(Strings.hostedCheckout.poll_succeeded(operationSessionID))
            return .finished(.succeeded)

        case let .failed(failure):
            Logger.warn(Strings.hostedCheckout.poll_failed(operationSessionID,
                                                           code: failure?.code,
                                                           message: failure?.message))

            guard failure?.isAlreadyPurchased != true else {
                return .finished(.alreadyPurchased)
            }

            return .finished(.failed(code: failure?.code, message: failure?.message))

        case .pending:
            return .retry
        }
    }

    /// `nil` when `deadline` comes first. A request cannot be cancelled, so one still out finishes unobserved.
    ///
    /// Waits in real time rather than on `sleeper`, since that is the time a request takes.
    func value<Value>(before deadline: Date, of operation: @escaping @Sendable () async -> Value) async -> Value? {
        let timeLimit = deadline.timeIntervalSince(self.dateProvider.now())

        return await withUnsafeContinuation { continuation in
            let resumed: Atomic<Bool> = false
            let finish: @Sendable (Value?) -> Void = { value in
                guard !resumed.getAndSet(true) else { return }
                continuation.resume(returning: value)
            }

            let timer = Task {
                guard (try? await TaskSleeper().sleep(seconds: timeLimit)) != nil else { return }
                finish(nil)
            }

            Task {
                finish(await operation())
                timer.cancel()
            }
        }
    }

}

// MARK: - Production seam impls

extension HostedCheckoutPoller {

    /// Cancelling the calling `Task` does not cancel the in-flight HTTP request.
    struct WebBillingStatusFetcher: HostedCheckoutStatusFetching {

        let webBillingAPI: WebBillingAPI

        func fetchStatus(
            operationSessionID: String,
            appUserID: String
        ) async -> Result<HostedCheckoutStatusResponse, BackendError> {
            return await Async.call { completion in
                self.webBillingAPI.getHostedCheckoutStatus(
                    appUserID: appUserID,
                    operationSessionID: operationSessionID,
                    completion: completion
                )
            }
        }

        func fetchPaymentStatus(
            operationSessionID: String,
            appUserID: String
        ) async -> Result<HostedCheckoutPaymentStatusResponse, BackendError> {
            return await Async.call { completion in
                self.webBillingAPI.getHostedCheckoutPaymentStatus(
                    appUserID: appUserID,
                    operationSessionID: operationSessionID,
                    completion: completion
                )
            }
        }

    }

    struct TaskSleeper: HostedCheckoutAsyncSleeper {

        func sleep(seconds: TimeInterval) async throws {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }

    }

}
