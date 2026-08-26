//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Checkpoints.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CustomVariableValue {

    var coreCheckpointValue: RevenueCat.CheckpointValue {
        return self.map(
            string: { .string($0) },
            number: { .double($0) },
            boolean: { .boolean($0) }
        )
    }

}

/// Per-call parameters for a checkpoint.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class CheckpointParams: Equatable, Hashable, CustomStringConvertible, @unchecked Sendable {

    /// Custom variables usable in checkpoint targeting rules and feature events.
    public let customVariables: [String: CustomVariableValue]

    /// Creates checkpoint parameters with the supplied custom variables.
    public init(customVariables: [String: CustomVariableValue] = [:]) {
        self.customVariables = RevenueCat.CustomVariableKeyValidator.validateAndFilter(customVariables)
    }

    /// Returns whether two parameter collections contain the same custom variables.
    public static func == (lhs: CheckpointParams, rhs: CheckpointParams) -> Bool {
        return lhs.customVariables == rhs.customVariables
    }

    /// Hashes the checkpoint parameters.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.customVariables)
    }

    /// A debug description of the checkpoint parameters.
    public var description: String {
        return "CheckpointParams(customVariables=\(self.customVariables))"
    }

    var coreParams: RevenueCat.CheckpointParams {
        return .init(customVariables: self.customVariables.mapValues(\.coreCheckpointValue))
    }

}

/// Information about a checkpoint that was hit.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class CheckpointInfo: Equatable, Hashable, CustomStringConvertible, @unchecked Sendable {

    /// The identifier of the checkpoint that was hit.
    public let identifier: String

    /// The custom variables supplied when the checkpoint was hit.
    public var customVariables: [String: CustomVariableValue] {
        return self.params.customVariables
    }

    private let params: CheckpointParams

    /// Creates checkpoint information for an identifier and its parameters.
    public init(identifier: String, params: CheckpointParams) {
        self.identifier = identifier
        self.params = params
    }

    /// Returns whether two checkpoint information values are equal.
    public static func == (lhs: CheckpointInfo, rhs: CheckpointInfo) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.customVariables == rhs.customVariables
    }

    /// Hashes the checkpoint information.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.identifier)
        hasher.combine(self.customVariables)
    }

    /// A debug description of the checkpoint information.
    public var description: String {
        return "CheckpointInfo(identifier='\(self.identifier)', customVariables=\(self.customVariables))"
    }

}

/// The reason no experience was served for a checkpoint.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class CheckpointNoActionReason: Equatable, Hashable, CustomStringConvertible, @unchecked Sendable {

    /// The value identifying the reason.
    public let value: String

    /// No targeting rule matched.
    public static let noMatch = CheckpointNoActionReason(value: "NO_MATCH")
    /// The customer was assigned to a holdout.
    public static let holdout = CheckpointNoActionReason(value: "HOLDOUT")
    /// The customer reached the configured frequency cap.
    public static let frequencyCapped = CheckpointNoActionReason(value: "FREQUENCY_CAPPED")
    /// Checkpoint configuration could not be loaded.
    public static let configurationUnavailable = CheckpointNoActionReason(value: "CONFIGURATION_UNAVAILABLE")
    /// Checkpoints are disabled.
    public static let disabled = CheckpointNoActionReason(value: "DISABLED")
    /// The checkpoint identifier is not configured.
    public static let unknownCheckpoint = CheckpointNoActionReason(value: "UNKNOWN_CHECKPOINT")
    /// The checkpoint identifier is invalid.
    public static let invalidCheckpointIdentifier = CheckpointNoActionReason(value: "INVALID_CHECKPOINT_IDENTIFIER")

    init(value: String) {
        self.value = value
    }

    /// Returns whether two no-action reasons have the same value.
    public static func == (lhs: CheckpointNoActionReason, rhs: CheckpointNoActionReason) -> Bool {
        return lhs.value == rhs.value
    }

    /// Hashes the no-action reason.
    public func hash(into hasher: inout Hasher) { hasher.combine(self.value) }

    /// A debug description of the no-action reason.
    public var description: String { return self.value }

}

/// Base class for the result of evaluating a checkpoint.
///
/// Inspect the concrete result type to determine what happened:
///
/// ```swift
/// let result = try await Purchases.shared.checkpoint("onboarding_complete")
///
/// switch result {
/// case let result as CheckpointPaywallPresentedResult:
///     handlePaywallOutcome(result.paywallOutcome)
/// case let result as CheckpointReceivedOfferingResult:
///     showOffering(result.offering)
/// case let result as CheckpointNoActionResult:
///     handleNoAction(result.reason)
/// default:
///     // Handle result types added in future SDK versions.
///     break
/// }
/// ```
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class CheckpointResult: Equatable, Hashable, CustomStringConvertible {

    /// Information about the checkpoint that produced this result.
    public let checkpoint: CheckpointInfo

    init(checkpoint: CheckpointInfo) {
        self.checkpoint = checkpoint
    }

    /// A debug description of the checkpoint result.
    public var description: String {
        return "CheckpointResult(checkpoint=\(self.checkpoint))"
    }

    /// Returns whether two checkpoint results are equal.
    public static func == (lhs: CheckpointResult, rhs: CheckpointResult) -> Bool {
        return lhs.isEqual(to: rhs)
    }

    func isEqual(to other: CheckpointResult) -> Bool {
        return type(of: self) == type(of: other) && self.checkpoint == other.checkpoint
    }

    /// Hashes the checkpoint result.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(type(of: self)))
        hasher.combine(self.checkpoint)
    }

}

/// Nothing was served for a checkpoint.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class CheckpointNoActionResult: CheckpointResult {

    /// The reason no experience was served.
    public let reason: CheckpointNoActionReason

    init(checkpoint: CheckpointInfo, reason: CheckpointNoActionReason) {
        self.reason = reason
        super.init(checkpoint: checkpoint)
    }

    public override var description: String {
        return "NoAction(checkpoint=\(self.checkpoint), reason=\(self.reason))"
    }

    override func isEqual(to other: CheckpointResult) -> Bool {
        guard let other = other as? CheckpointNoActionResult else { return false }
        return self.checkpoint == other.checkpoint && self.reason == other.reason
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(self.checkpoint)
        hasher.combine(self.reason)
    }

}

/// An offering was selected for a checkpoint, with no RevenueCat-managed UI presented. The app decides
/// whether and how to use it.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class CheckpointReceivedOfferingResult: CheckpointResult {

    /// The offering the checkpoint selected.
    public let offering: Offering

    init(checkpoint: CheckpointInfo, offering: Offering) {
        self.offering = offering
        super.init(checkpoint: checkpoint)
    }

    public override var description: String {
        return "ReceivedOffering(checkpoint=\(self.checkpoint), offering=\(self.offering.identifier))"
    }

    override func isEqual(to other: CheckpointResult) -> Bool {
        guard let other = other as? CheckpointReceivedOfferingResult else { return false }
        return self.checkpoint == other.checkpoint && self.offering == other.offering
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(self.checkpoint)
        hasher.combine(self.offering)
    }

}

/// Global listener for checkpoint activity. All methods are called on the main thread.
///
/// ``CheckpointListener/onCheckpointHit(_:)`` is called before evaluation starts. After evaluation and any
/// presented UI finish, ``CheckpointListener/onCheckpointCompleted(_:result:)`` is called before the per-call
/// checkpoint API delivers its result.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public protocol CheckpointListener: AnyObject {

    /// A checkpoint was hit and evaluation is about to start.
    ///
    /// This does not indicate that a targeting rule matched or that UI will be presented.
    func onCheckpointHit(_ checkpoint: CheckpointInfo)
    /// Checkpoint evaluation and any presented UI finished.
    ///
    /// This is called before the per-call checkpoint API delivers its result.
    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult)

}

@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public extension CheckpointListener {

    /// Default no-op implementation.
    func onCheckpointHit(_ checkpoint: CheckpointInfo) {}
    /// Default no-op implementation.
    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult) {}

}
