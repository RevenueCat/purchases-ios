//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointAdOutcome.swift
//

import Foundation
@_spi(Internal) import RevenueCat

/// A checkpoint-triggered ad was auto-presented by a registered ``CheckpointAdHandler`` and finished.
///
/// This is only ever produced when a handler is registered (e.g. by an ad adapter such as
/// `purchases-ios-admob`) via `Purchases.checkpointAdHandler`. Without one, a resolved ad checkpoint
/// still comes back as a data-only ``CheckpointAdResult`` instead.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class CheckpointAdPresentedResult: CheckpointResult {

    /// The terminal outcome of the presented ad.
    public let outcome: CheckpointAdOutcome

    init(checkpoint: CheckpointInfo, outcome: CheckpointAdOutcome) {
        self.outcome = outcome
        super.init(checkpoint: checkpoint)
    }

    public override var description: String {
        return "AdPresented(checkpoint=\(self.checkpoint), outcome=\(self.outcome))"
    }

    override func isEqual(to other: CheckpointResult) -> Bool {
        guard let other = other as? CheckpointAdPresentedResult else { return false }
        return self.checkpoint == other.checkpoint && self.outcome == other.outcome
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(self.checkpoint)
        hasher.combine(self.outcome)
    }

}

/// Base class for the terminal outcome of a checkpoint-presented ad.
///
/// Inspect the concrete outcome type to determine how the ad finished:
///
/// ```swift
/// switch presented.outcome {
/// case is CheckpointAdShownOutcome:
///     // fully shown and dismissed
/// case let outcome as CheckpointAdFailedOutcome:
///     handleError(outcome.error)
/// default:
///     // Handle outcome types added in future SDK versions.
///     break
/// }
/// ```
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class CheckpointAdOutcome: Equatable, Hashable, CustomStringConvertible {

    fileprivate init() {}

    /// A debug description of the ad outcome.
    public var description: String { return "CheckpointAdOutcome" }

    /// Returns whether two ad outcomes are equal.
    public static func == (lhs: CheckpointAdOutcome, rhs: CheckpointAdOutcome) -> Bool {
        return lhs.isEqual(to: rhs)
    }

    func isEqual(to other: CheckpointAdOutcome) -> Bool {
        return type(of: self) == type(of: other)
    }

    /// Hashes the ad outcome.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(type(of: self)))
    }

}

/// The ad was fully shown and dismissed.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class CheckpointAdShownOutcome: CheckpointAdOutcome {

    static let shared = CheckpointAdShownOutcome()

    private override init() { super.init() }

    public override var description: String { return "Shown" }

}

/// The ad failed to load or present.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class CheckpointAdFailedOutcome: CheckpointAdOutcome {

    /// The error that ended the ad presentation attempt.
    public let error: PublicError

    init(error: PublicError) {
        self.error = error
        super.init()
    }

    public override var description: String { return "Failed(error=\(self.error))" }

    override func isEqual(to other: CheckpointAdOutcome) -> Bool {
        return (other as? CheckpointAdFailedOutcome)?.error.isEqual(self.error) == true
    }

    public override func hash(into hasher: inout Hasher) { hasher.combine(self.error.hash) }

}
