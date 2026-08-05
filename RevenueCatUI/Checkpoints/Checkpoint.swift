//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Checkpoint.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// Per-call parameters for ``Purchases/checkpoint(_:params:)``.
///
/// Custom property values must be a `String`, number, or `Bool`.
@_spi(Internal) public struct CheckpointParams: Equatable {

    /// Custom properties usable in checkpoint targeting rules.
    public let customProperties: [String: Any]

    /// Creates parameters with optional custom properties.
    public init(customProperties: [String: Any] = [:]) {
        self.customProperties = customProperties.reduce(into: [:]) { validProperties, property in
            let (key, value) = property
            guard Self.isValidCustomPropertyValue(value) else {
                Logger.warning(
                    "Dropping invalid checkpoint custom property '\(key)': " +
                    String(reflecting: type(of: value))
                )
                return
            }
            validProperties[key] = value
        }
    }

    private static func isValidCustomPropertyValue(_ value: Any) -> Bool {
        switch value {
        case is String, is Bool,
             is Int, is Int8, is Int16, is Int32, is Int64,
             is UInt, is UInt8, is UInt16, is UInt32, is UInt64,
             is Float, is Double, is Decimal, is NSNumber:
            return true
        default:
            return false
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.customProperties as NSDictionary).isEqual(to: rhs.customProperties)
    }

}

extension CheckpointParams {

    var engineValue: CheckpointEngineParams {
        return CheckpointEngineParams(customProperties: self.customProperties)
    }

    init(_ params: CheckpointEngineParams) {
        self.init(customProperties: params.customProperties)
    }

}

/// Information about a checkpoint that was hit.
@_spi(Internal) public struct CheckpointInfo: Equatable {

    /// The checkpoint identifier configured in the RevenueCat dashboard.
    public let identifier: String

    /// The parameters registered with the checkpoint.
    public let params: CheckpointParams

    init(identifier: String, params: CheckpointParams) {
        self.identifier = identifier
        self.params = params
    }

}

extension CheckpointInfo {

    init(_ checkpoint: CheckpointEngineInfo) {
        self.init(identifier: checkpoint.identifier, params: CheckpointParams(checkpoint.params))
    }

}

/// The reason no experience was served for a checkpoint.
@_spi(Internal) public struct CheckpointNoActionReason: Equatable, Hashable, Sendable {

    /// The value identifying the reason.
    public let value: String

    /// No targeting rule matched.
    public static let noMatch = Self(value: "NO_MATCH")

    /// The customer was assigned to a holdout.
    public static let holdout = Self(value: "HOLDOUT")

    /// The customer reached the configured frequency cap.
    public static let frequencyCapped = Self(value: "FREQUENCY_CAPPED")

    /// Checkpoint configuration could not be loaded.
    public static let configurationUnavailable = Self(value: "CONFIGURATION_UNAVAILABLE")

    /// Checkpoints are disabled.
    public static let disabled = Self(value: "DISABLED")

    init(value: String) {
        self.value = value
    }

}

extension CheckpointNoActionReason {

    init(_ reason: CheckpointEngineNoActionReason) {
        self.init(value: reason.value)
    }

}

/// Base class for the result of hitting a checkpoint.
///
/// Inspect the concrete subclass to determine the outcome. This class cannot be initialized or subclassed outside
/// the SDK, allowing RevenueCat to add new result subclasses without breaking exhaustive switches in applications.
@_spi(Internal) public class CheckpointResult: CustomStringConvertible, Equatable {

    /// Information about the checkpoint that produced this result.
    public let checkpoint: CheckpointInfo

    fileprivate init(checkpoint: CheckpointInfo) {
        self.checkpoint = checkpoint
    }

    /// A debug description of the checkpoint result.
    public var description: String {
        return "CheckpointResult(checkpoint=\(self.checkpoint))"
    }

    public static func == (lhs: CheckpointResult, rhs: CheckpointResult) -> Bool {
        return lhs.isEqual(to: rhs)
    }

    fileprivate func isEqual(to other: CheckpointResult) -> Bool {
        return type(of: self) == type(of: other) && self.checkpoint == other.checkpoint
    }

}

/// A checkpoint-triggered paywall was presented and finished.
@_spi(Internal) public final class CheckpointPaywallPresentedResult: CheckpointResult {

    /// The terminal outcome of the presented paywall.
    public let paywallOutcome: CheckpointPaywallOutcome

    init(checkpoint: CheckpointInfo, paywallOutcome: CheckpointPaywallOutcome) {
        self.paywallOutcome = paywallOutcome
        super.init(checkpoint: checkpoint)
    }

    /// A debug description of the presented-paywall result.
    public override var description: String {
        return "PaywallPresented(checkpoint=\(self.checkpoint), paywallOutcome=\(self.paywallOutcome))"
    }

    fileprivate override func isEqual(to other: CheckpointResult) -> Bool {
        guard let other = other as? CheckpointPaywallPresentedResult else { return false }
        return self.checkpoint == other.checkpoint && self.paywallOutcome == other.paywallOutcome
    }

}

/// Nothing was served for a checkpoint.
@_spi(Internal) public final class CheckpointNoActionResult: CheckpointResult {

    /// The reason no experience was served.
    public let reason: CheckpointNoActionReason

    init(checkpoint: CheckpointInfo, reason: CheckpointNoActionReason) {
        self.reason = reason
        super.init(checkpoint: checkpoint)
    }

    /// A debug description of the no-action result.
    public override var description: String {
        return "NoAction(checkpoint=\(self.checkpoint), reason=\(self.reason))"
    }

    fileprivate override func isEqual(to other: CheckpointResult) -> Bool {
        guard let other = other as? CheckpointNoActionResult else { return false }
        return self.checkpoint == other.checkpoint && self.reason == other.reason
    }

}

/// Base class for the terminal result of a checkpoint-presented paywall.
///
/// Inspect the concrete subclass to determine the outcome. This class cannot be initialized or subclassed outside
/// the SDK, allowing RevenueCat to add new result subclasses without breaking exhaustive switches in applications.
@_spi(Internal) public class CheckpointPaywallOutcome: CustomStringConvertible, Equatable {

    fileprivate init() {}

    /// A debug description of the paywall outcome.
    public var description: String {
        return "CheckpointPaywallOutcome"
    }

    public static func == (lhs: CheckpointPaywallOutcome, rhs: CheckpointPaywallOutcome) -> Bool {
        return lhs.isEqual(to: rhs)
    }

    fileprivate func isEqual(to other: CheckpointPaywallOutcome) -> Bool {
        return type(of: self) == type(of: other)
    }

}

/// The customer dismissed the paywall.
@_spi(Internal) public final class CheckpointPaywallDismissedOutcome: CheckpointPaywallOutcome {

    /// The dismissed paywall outcome.
    public static let shared = CheckpointPaywallDismissedOutcome()

    private override init() {
        super.init()
    }

    /// A debug description of the dismissed outcome.
    public override var description: String { return "Dismissed" }

}

/// The customer completed a purchase.
@_spi(Internal) public final class CheckpointPaywallPurchasedOutcome: CheckpointPaywallOutcome {

    /// Customer information after the completed purchase.
    public let customerInfo: CustomerInfo

    /// Creates a purchased outcome with the latest customer information.
    public init(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        super.init()
    }

    /// A debug description of the purchased outcome.
    public override var description: String { return "Purchased" }

    fileprivate override func isEqual(to other: CheckpointPaywallOutcome) -> Bool {
        guard let other = other as? CheckpointPaywallPurchasedOutcome else { return false }
        return self.customerInfo.isEqual(other.customerInfo)
    }

}

/// The customer restored purchases.
@_spi(Internal) public final class CheckpointPaywallRestoredOutcome: CheckpointPaywallOutcome {

    /// Customer information after restoring purchases.
    public let customerInfo: CustomerInfo

    /// Creates a restored outcome with the latest customer information.
    public init(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        super.init()
    }

    /// A debug description of the restored outcome.
    public override var description: String { return "Restored" }

    fileprivate override func isEqual(to other: CheckpointPaywallOutcome) -> Bool {
        guard let other = other as? CheckpointPaywallRestoredOutcome else { return false }
        return self.customerInfo.isEqual(other.customerInfo)
    }

}

/// The paywall ended with an error.
@_spi(Internal) public final class CheckpointPaywallErrorOutcome: CheckpointPaywallOutcome {

    /// The error that ended the checkpoint experience.
    public let error: PublicError

    /// Creates a paywall error outcome.
    public init(error: PublicError) {
        self.error = error
        super.init()
    }

    /// A debug description of the error outcome.
    public override var description: String {
        return "Error(error=\(self.error))"
    }

    fileprivate override func isEqual(to other: CheckpointPaywallOutcome) -> Bool {
        guard let other = other as? CheckpointPaywallErrorOutcome else { return false }
        return self.error.isEqual(other.error)
    }

}

/// Global listener for checkpoint activity.
///
/// All methods are called on the main thread.
@_spi(Internal) public protocol CheckpointListener: AnyObject {

    /// A checkpoint was hit, before evaluation.
    func onCheckpointHit(_ checkpoint: CheckpointInfo)

    /// The checkpoint was resolved and the outcome was returned.
    func onCheckpointResolved(_ checkpoint: CheckpointInfo, result: CheckpointResult)

    /// A checkpoint-presented paywall finished.
    func onCheckpointPaywallFinished(_ checkpoint: CheckpointInfo, outcome: CheckpointPaywallOutcome)

}

@_spi(Internal) public extension CheckpointListener {

    /// Default no-op implementation.
    func onCheckpointHit(_ checkpoint: CheckpointInfo) {}

    /// Default no-op implementation.
    func onCheckpointResolved(_ checkpoint: CheckpointInfo, result: CheckpointResult) {}

    /// Default no-op implementation.
    func onCheckpointPaywallFinished(_ checkpoint: CheckpointInfo, outcome: CheckpointPaywallOutcome) {}

}

// MARK: - Debug descriptions

extension CheckpointParams: CustomStringConvertible {

    /// A debug description of the checkpoint parameters.
    public var description: String {
        return "CheckpointParams(customProperties=\(self.customProperties))"
    }

}

extension CheckpointInfo: CustomStringConvertible {

    /// A debug description of the checkpoint information.
    public var description: String {
        return "CheckpointInfo(identifier='\(self.identifier)', params=\(self.params))"
    }

}

extension CheckpointNoActionReason: CustomStringConvertible {

    /// The raw reason value.
    public var description: String { return self.value }

}

extension CheckpointResult {

    static func from(_ result: CheckpointEngineResult) -> CheckpointResult {
        switch result {
        case let .paywallPresented(checkpoint, outcome):
            return CheckpointPaywallPresentedResult(
                checkpoint: CheckpointInfo(checkpoint),
                paywallOutcome: CheckpointPaywallOutcome.from(outcome)
            )
        case let .noAction(checkpoint, reason):
            return CheckpointNoActionResult(
                checkpoint: CheckpointInfo(checkpoint),
                reason: CheckpointNoActionReason(reason)
            )
        }
    }

}

extension CheckpointPaywallOutcome {

    static func from(_ outcome: CheckpointEnginePaywallOutcome) -> CheckpointPaywallOutcome {
        switch outcome {
        case .dismissed:
            return CheckpointPaywallDismissedOutcome.shared
        case let .purchased(customerInfo):
            return CheckpointPaywallPurchasedOutcome(customerInfo: customerInfo)
        case let .restored(customerInfo):
            return CheckpointPaywallRestoredOutcome(customerInfo: customerInfo)
        case let .error(error):
            return CheckpointPaywallErrorOutcome(error: error)
        }
    }

}
