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

import Foundation
@_spi(Internal) import RevenueCat

/// A custom value supplied when a checkpoint is hit.
@_spi(CheckpointsInternal)
public struct CheckpointValue: Equatable, Hashable, Sendable {

    fileprivate let coreValue: RevenueCat.CheckpointValue

    private init(coreValue: RevenueCat.CheckpointValue) {
        self.coreValue = coreValue
    }

    /// Creates a string checkpoint value.
    public static func string(_ value: String) -> Self { return .init(coreValue: .string(value)) }
    /// Creates an integer checkpoint value.
    public static func integer(_ value: Int64) -> Self { return .init(coreValue: .integer(value)) }
    /// Creates a floating-point checkpoint value.
    public static func double(_ value: Double) -> Self { return .init(coreValue: .double(value)) }
    /// Creates a Boolean checkpoint value.
    public static func boolean(_ value: Bool) -> Self { return .init(coreValue: .boolean(value)) }

}

extension CheckpointValue: ExpressibleByStringLiteral {

    /// Creates a string checkpoint value from a string literal.
    public init(stringLiteral value: String) { self = .string(value) }

}

extension CheckpointValue: ExpressibleByIntegerLiteral {

    /// Creates an integer checkpoint value from an integer literal.
    public init(integerLiteral value: Int64) { self = .integer(value) }

}

extension CheckpointValue: ExpressibleByFloatLiteral {

    /// Creates a floating-point checkpoint value from a floating-point literal.
    public init(floatLiteral value: Double) { self = .double(value) }

}

extension CheckpointValue: ExpressibleByBooleanLiteral {

    /// Creates a Boolean checkpoint value from a Boolean literal.
    public init(booleanLiteral value: Bool) { self = .boolean(value) }

}

extension CheckpointValue: Codable {

    /// Creates a checkpoint value by decoding a primitive JSON value.
    public init(from decoder: Decoder) throws {
        self.init(coreValue: try RevenueCat.CheckpointValue(from: decoder))
    }

    /// Encodes the checkpoint value as a primitive JSON value.
    public func encode(to encoder: Encoder) throws {
        try self.coreValue.encode(to: encoder)
    }

}

extension CheckpointValue {

    /// Creates a checkpoint value from a supported Foundation primitive.
    public init?(foundationValue: Any) {
        guard let coreValue = RevenueCat.CheckpointValue(foundationValue: foundationValue) else { return nil }
        self.init(coreValue: coreValue)
    }

    /// The equivalent Foundation primitive value.
    public var foundationValue: Any {
        return self.coreValue.foundationValue
    }

}

/// Per-call parameters for a checkpoint.
@_spi(CheckpointsInternal)
public final class CheckpointParams: Equatable, Hashable, CustomStringConvertible, @unchecked Sendable {

    /// Custom variables usable in checkpoint targeting rules and feature events.
    public let customVariables: [String: CheckpointValue]

    /// Creates checkpoint parameters with the supplied custom variables.
    public init(customVariables: [String: CheckpointValue] = [:]) {
        self.customVariables = customVariables
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
        return .init(customVariables: self.customVariables.mapValues(\.coreValue))
    }

}

/// Information about a checkpoint that was hit.
@_spi(CheckpointsInternal)
public final class CheckpointInfo: Equatable, Hashable, CustomStringConvertible, @unchecked Sendable {

    /// The identifier of the checkpoint that was hit.
    public let identifier: String

    /// The parameters supplied when the checkpoint was hit.
    public let params: CheckpointParams

    /// Creates checkpoint information for an identifier and its parameters.
    public init(identifier: String, params: CheckpointParams) {
        self.identifier = identifier
        self.params = params
    }

    /// Returns whether two checkpoint information values are equal.
    public static func == (lhs: CheckpointInfo, rhs: CheckpointInfo) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.params == rhs.params
    }

    /// Hashes the checkpoint information.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.identifier)
        hasher.combine(self.params)
    }

    /// A debug description of the checkpoint information.
    public var description: String {
        return "CheckpointInfo(identifier='\(self.identifier)', params=\(self.params))"
    }

}

/// The reason no experience was served for a checkpoint.
@_spi(CheckpointsInternal)
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

/// Base class for the result of hitting a checkpoint.
@_spi(CheckpointsInternal)
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
@_spi(CheckpointsInternal)
public protocol CheckpointListener: AnyObject {

    /// A checkpoint was hit, before evaluation.
    func onCheckpointHit(_ checkpoint: CheckpointInfo)
    /// The checkpoint completed and its result was returned.
    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult)

}

@_spi(CheckpointsInternal)
public extension CheckpointListener {

    /// Default no-op implementation.
    func onCheckpointHit(_ checkpoint: CheckpointInfo) {}
    /// Default no-op implementation.
    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult) {}

}
