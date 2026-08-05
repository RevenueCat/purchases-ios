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

import CoreFoundation
import Foundation

/// A custom value supplied when a checkpoint is hit.
@_spi(Internal) public enum CheckpointValue: Equatable, Hashable, Sendable {

    /// A string value.
    case string(String)
    /// An integer value.
    case integer(Int64)
    /// A floating-point value.
    case double(Double)
    /// A Boolean value.
    case boolean(Bool)

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
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .integer(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected a string, integer, double, or boolean."
                )
            )
        }
    }

    /// Encodes the checkpoint value as a primitive JSON value.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .string(value): try container.encode(value)
        case let .integer(value): try container.encode(value)
        case let .double(value): try container.encode(value)
        case let .boolean(value): try container.encode(value)
        }
    }

}

extension CheckpointValue {

    /// Creates a checkpoint value from a supported Foundation primitive.
    public init?(foundationValue: Any) {
        if let value = foundationValue as? String {
            self = .string(value)
            return
        }

        guard let number = foundationValue as? NSNumber else { return nil }
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
            self = .boolean(number.boolValue)
            return
        }

        switch String(cString: number.objCType) {
        case "c", "i", "s", "l", "q", "C", "I", "S", "L", "Q":
            guard let value = Int64(number.stringValue) else { return nil }
            self = .integer(value)
        default:
            self = .double(number.doubleValue)
        }
    }

    /// The equivalent Foundation primitive value.
    public var foundationValue: Any {
        switch self {
        case let .string(value): return value
        case let .integer(value): return NSNumber(value: value)
        case let .double(value): return NSNumber(value: value)
        case let .boolean(value): return NSNumber(value: value)
        }
    }

}

/// Per-call parameters for a checkpoint.
@_spi(Internal) public struct CheckpointParams: Equatable, Hashable, Sendable {

    /// Custom properties usable in checkpoint targeting rules and feature events.
    public let customProperties: [String: CheckpointValue]

    /// Creates checkpoint parameters with the supplied custom properties.
    public init(customProperties: [String: CheckpointValue] = [:]) {
        self.customProperties = customProperties
    }

}

/// Information about a checkpoint that was hit.
@_spi(Internal) public struct CheckpointInfo: Equatable, Hashable, Sendable {

    /// The identifier of the checkpoint that was hit.
    public let identifier: String
    /// The parameters supplied when the checkpoint was hit.
    public let params: CheckpointParams

    /// Creates checkpoint information for an identifier and its parameters.
    public init(identifier: String, params: CheckpointParams) {
        self.identifier = identifier
        self.params = params
    }

}

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

/// Internal representation of why a checkpoint did not run anything.
@_spi(Internal) public struct CheckpointEngineNoActionReason: Equatable, Sendable {

    /// The raw no-action reason value.
    public let value: String

    /// No targeting rule matched the checkpoint.
    public static let noMatch = Self(value: "NO_MATCH")
    /// The customer belongs to the experiment holdout.
    public static let holdout = Self(value: "HOLDOUT")
    /// The checkpoint was frequency capped.
    public static let frequencyCapped = Self(value: "FREQUENCY_CAPPED")
    /// The checkpoint configuration could not be loaded.
    public static let configurationUnavailable = Self(value: "CONFIGURATION_UNAVAILABLE")
    /// Checkpoints are disabled.
    public static let disabled = Self(value: "DISABLED")

    /// Creates a no-action reason from its raw value.
    public init(value: String) {
        self.value = value
    }

}

/// Internal checkpoint result returned to RevenueCatUI for conversion into its public result hierarchy.
@_spi(Internal) public enum CheckpointEngineResult {

    /// A paywall was presented and produced a terminal outcome.
    case paywallPresented(checkpoint: CheckpointInfo, outcome: CheckpointEnginePaywallOutcome)
    /// The checkpoint produced no action.
    case noAction(checkpoint: CheckpointInfo, reason: CheckpointEngineNoActionReason)

    /// Information about the checkpoint that produced the result.
    public var checkpoint: CheckpointInfo {
        switch self {
        case let .paywallPresented(checkpoint, _), let .noAction(checkpoint, _):
            return checkpoint
        }
    }

}

/// Internal terminal result of a checkpoint-presented paywall.
@_spi(Internal) public enum CheckpointEnginePaywallOutcome {

    /// The paywall was dismissed without a purchase or restore.
    case dismissed
    /// The customer completed a purchase.
    case purchased(CustomerInfo)
    /// The customer restored purchases.
    case restored(CustomerInfo)
    /// The paywall finished with an error.
    case error(PublicError)

}

/// Input supplied by the core checkpoint engine to RevenueCatUI for presentation.
@_spi(Internal) public class CheckpointEnginePresentation {

    /// Information about the checkpoint being presented.
    public let checkpoint: CheckpointInfo

    /// Creates a presentation for a checkpoint.
    public init(checkpoint: CheckpointInfo) {
        self.checkpoint = checkpoint
    }

}

/// Presentation capability supplied directly by RevenueCatUI when a checkpoint API is called.
@MainActor
@_spi(Internal) public protocol CheckpointEnginePresenter: AnyObject {

    /// Presents the resolved checkpoint workflow.
    func present(
        callID: String,
        presentation: CheckpointEnginePresentation,
        delegate: CheckpointEnginePresenterDelegate
    )

}

/// Receives terminal results from the RevenueCatUI presenter.
@_spi(Internal) public protocol CheckpointEnginePresenterDelegate: AnyObject {

    /// Reports the terminal outcome for a presented checkpoint paywall.
    func onCheckpointPaywallFinished(callID: String, outcome: CheckpointEnginePaywallOutcome)

}

/// Receives checkpoint engine events for conversion into the RevenueCatUI public listener API.
@_spi(Internal) public protocol CheckpointEngineListener: AnyObject {

    /// Called when a checkpoint is hit.
    func onCheckpointHit(_ checkpoint: CheckpointInfo)
    /// Called when checkpoint resolution finishes.
    func onCheckpointResolved(_ checkpoint: CheckpointInfo, result: CheckpointEngineResult)
    /// Called when a checkpoint paywall finishes.
    func onCheckpointPaywallFinished(
        _ checkpoint: CheckpointInfo,
        outcome: CheckpointEnginePaywallOutcome
    )

}
