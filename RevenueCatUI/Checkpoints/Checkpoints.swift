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

#if ENABLE_CHECKPOINTS

import Foundation
@_spi(Internal) import RevenueCat

/// A custom value supplied when a checkpoint is hit.
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
@objc(RCCheckpointParams)
public final class CheckpointParams: NSObject, @unchecked Sendable {

    /// Custom properties usable in checkpoint targeting rules and feature events.
    public let customProperties: [String: CheckpointValue]

    /// Creates checkpoint parameters with the supplied custom properties.
    public init(customProperties: [String: CheckpointValue] = [:]) {
        self.customProperties = customProperties
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CheckpointParams else { return false }
        return self.customProperties == other.customProperties
    }

    public override var hash: Int { return self.customProperties.hashValue }

    /// A debug description of the checkpoint parameters.
    public override var description: String {
        return "CheckpointParams(customProperties=\(self.customProperties))"
    }

    var coreParams: RevenueCat.CheckpointParams {
        return .init(customProperties: self.customProperties.mapValues(\.coreValue))
    }

}

@objc extension CheckpointParams {

    /// Creates checkpoint parameters from Objective-C Foundation primitive values. Unsupported values are dropped.
    @objc(initWithCustomProperties:)
    public convenience init(objcCustomProperties: NSDictionary) {
        var values: [String: CheckpointValue] = [:]
        for (rawKey, rawValue) in objcCustomProperties {
            guard let key = rawKey as? String,
                  let value = CheckpointValue(foundationValue: rawValue) else {
                Logger.warning(CheckpointStrings.invalidObjectiveCCustomProperty(type(of: rawValue)))
                continue
            }
            values[key] = value
        }
        self.init(customProperties: values)
    }

    /// The custom properties as Objective-C Foundation primitive values.
    @objc(customProperties)
    public var objcCustomProperties: NSDictionary {
        return self.customProperties.mapValues { $0.foundationValue } as NSDictionary
    }

}

private enum CheckpointStrings: LogMessage {

    case invalidObjectiveCCustomProperty(Any.Type)

    var description: String {
        switch self {
        case let .invalidObjectiveCCustomProperty(type):
            return "Dropping invalid Objective-C checkpoint custom property: \(String(reflecting: type))"
        }
    }

    var category: String { return "checkpoints" }

}

/// Information about a checkpoint that was hit.
@objc(RCCheckpointInfo)
public final class CheckpointInfo: NSObject, @unchecked Sendable {

    /// The identifier of the checkpoint that was hit.
    @objc
    public let identifier: String

    /// The parameters supplied when the checkpoint was hit.
    @objc
    public let params: CheckpointParams

    /// Creates checkpoint information for an identifier and its parameters.
    @objc
    public init(identifier: String, params: CheckpointParams) {
        self.identifier = identifier
        self.params = params
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CheckpointInfo else { return false }
        return self.identifier == other.identifier && self.params == other.params
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.identifier)
        hasher.combine(self.params)
        return hasher.finalize()
    }

    public override var description: String {
        return "CheckpointInfo(identifier='\(self.identifier)', params=\(self.params))"
    }

}

/// The reason no experience was served for a checkpoint.
@objc(RCCheckpointNoActionReason)
public final class CheckpointNoActionReason: NSObject, @unchecked Sendable {

    /// The value identifying the reason.
    @objc
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

    init(value: String) {
        self.value = value
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        return (object as? CheckpointNoActionReason)?.value == self.value
    }

    public override var hash: Int { return self.value.hashValue }
    public override var description: String { return self.value }

}

/// Base class for the result of hitting a checkpoint.
@objc(RCCheckpointResult)
public class CheckpointResult: NSObject {

    /// Information about the checkpoint that produced this result.
    @objc
    public let checkpoint: CheckpointInfo

    init(checkpoint: CheckpointInfo) {
        self.checkpoint = checkpoint
        super.init()
    }

    public override var description: String {
        return "CheckpointResult(checkpoint=\(self.checkpoint))"
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CheckpointResult else { return false }
        return type(of: self) == type(of: other) && self.checkpoint == other.checkpoint
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(ObjectIdentifier(type(of: self)))
        hasher.combine(self.checkpoint)
        return hasher.finalize()
    }

}

/// Nothing was served for a checkpoint.
@objc(RCCheckpointNoActionResult)
public final class CheckpointNoActionResult: CheckpointResult {

    /// The reason no experience was served.
    @objc
    public let reason: CheckpointNoActionReason

    init(checkpoint: CheckpointInfo, reason: CheckpointNoActionReason) {
        self.reason = reason
        super.init(checkpoint: checkpoint)
    }

    public override var description: String {
        return "NoAction(checkpoint=\(self.checkpoint), reason=\(self.reason))"
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CheckpointNoActionResult else { return false }
        return self.checkpoint == other.checkpoint && self.reason == other.reason
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.checkpoint)
        hasher.combine(self.reason)
        return hasher.finalize()
    }

}

/// Global listener for checkpoint activity. All methods are called on the main thread.
public protocol CheckpointListener: AnyObject {

    /// A checkpoint was hit, before evaluation.
    func onCheckpointHit(_ checkpoint: CheckpointInfo)
    /// The checkpoint completed and its result was returned.
    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult)

}

public extension CheckpointListener {

    /// Default no-op implementation.
    func onCheckpointHit(_ checkpoint: CheckpointInfo) {}
    /// Default no-op implementation.
    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult) {}

}

#endif
