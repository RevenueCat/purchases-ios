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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointCallParams: @unchecked Sendable {

    let customVariables: [String: CustomVariableValue]

    init(customVariables: [String: CustomVariableValue] = [:]) {
        self.customVariables = RevenueCat.CustomVariableKeyValidator.validateAndFilter(customVariables)
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
    public let customVariables: [String: CustomVariableValue]

    init(identifier: String, params: CheckpointCallParams) {
        self.identifier = identifier
        self.customVariables = params.customVariables
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

    let value: String

    /// No targeting rule matched.
    public static let noMatch = CheckpointNoActionReason(value: "NO_MATCH")
    /// The customer was assigned to a holdout.
    public static let holdout = CheckpointNoActionReason(value: "HOLDOUT")
    /// The customer reached the configured frequency cap.
    public static let frequencyCapped = CheckpointNoActionReason(value: "FREQUENCY_CAPPED")
    /// The checkpoint could not be evaluated because required configuration or resources were unavailable.
    public static let configurationUnavailable = CheckpointNoActionReason(value: "CONFIGURATION_UNAVAILABLE")
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

/// Presents an ad resolved by a checkpoint, registered via `Purchases.checkpointAdHandler`.
///
/// RevenueCatUI has no dependency on any ad SDK, so it can't present an ad itself — this is the
/// extension point an ad adapter (e.g. `purchases-ios-admob`) installs to make `Purchases.checkpoint(_:)`
/// auto-present ads the same way it already auto-presents paywalls. Without a registered handler, a
/// resolved ad checkpoint comes back as a data-only ``CheckpointAdResult`` instead, as it does today.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public protocol CheckpointAdHandler: AnyObject {

    /// Loads and presents an ad for `adUnitId`, returning only once it has been fully shown and
    /// dismissed, or throwing if it failed to load or present. Must always return or throw — never
    /// hang indefinitely — since the caller's `checkpoint(_:)` call awaits this directly.
    func present(checkpoint: CheckpointInfo, adUnitId: String) async throws

}
