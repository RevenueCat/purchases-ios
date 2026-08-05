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

    case string(String)
    case integer(Int64)
    case double(Double)
    case boolean(Bool)

}

extension CheckpointValue: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) { self = .string(value) }

}

extension CheckpointValue: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: Int64) { self = .integer(value) }

}

extension CheckpointValue: ExpressibleByFloatLiteral {

    public init(floatLiteral value: Double) { self = .double(value) }

}

extension CheckpointValue: ExpressibleByBooleanLiteral {

    public init(booleanLiteral value: Bool) { self = .boolean(value) }

}

extension CheckpointValue: Codable {

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

    public init(customProperties: [String: CheckpointValue] = [:]) {
        self.customProperties = customProperties
    }

}

/// Information about a checkpoint that was hit.
@_spi(Internal) public struct CheckpointInfo: Equatable, Hashable, Sendable {

    public let identifier: String
    public let params: CheckpointParams

    public init(identifier: String, params: CheckpointParams) {
        self.identifier = identifier
        self.params = params
    }

}

extension CheckpointParams: CustomStringConvertible {

    public var description: String {
        return "CheckpointParams(customProperties=\(self.customProperties))"
    }

}

extension CheckpointInfo: CustomStringConvertible {

    public var description: String {
        return "CheckpointInfo(identifier='\(self.identifier)', params=\(self.params))"
    }

}

/// Internal representation of why a checkpoint did not run anything.
@_spi(Internal) public struct CheckpointEngineNoActionReason: Equatable, Sendable {

    public let value: String

    public static let noMatch = Self(value: "NO_MATCH")
    public static let holdout = Self(value: "HOLDOUT")
    public static let frequencyCapped = Self(value: "FREQUENCY_CAPPED")
    public static let configurationUnavailable = Self(value: "CONFIGURATION_UNAVAILABLE")
    public static let disabled = Self(value: "DISABLED")

    public init(value: String) {
        self.value = value
    }

}

/// Internal checkpoint result returned to RevenueCatUI for conversion into its public result hierarchy.
@_spi(Internal) public enum CheckpointEngineResult {

    case paywallPresented(checkpoint: CheckpointInfo, outcome: CheckpointEnginePaywallOutcome)
    case noAction(checkpoint: CheckpointInfo, reason: CheckpointEngineNoActionReason)

    public var checkpoint: CheckpointInfo {
        switch self {
        case let .paywallPresented(checkpoint, _), let .noAction(checkpoint, _):
            return checkpoint
        }
    }

}

/// Internal terminal result of a checkpoint-presented paywall.
@_spi(Internal) public enum CheckpointEnginePaywallOutcome {

    case dismissed
    case purchased(CustomerInfo)
    case restored(CustomerInfo)
    case error(PublicError)

}

/// Input supplied by the core checkpoint engine to RevenueCatUI for presentation.
@_spi(Internal) public class CheckpointEnginePresentation {

    public let checkpoint: CheckpointInfo

    public init(checkpoint: CheckpointInfo) {
        self.checkpoint = checkpoint
    }

}

/// Presentation capability supplied directly by RevenueCatUI when a checkpoint API is called.
@MainActor
@_spi(Internal) public protocol CheckpointEnginePresenter: AnyObject {

    func present(
        callID: String,
        presentation: CheckpointEnginePresentation,
        delegate: CheckpointEnginePresenterDelegate
    )

}

/// Receives terminal results from the RevenueCatUI presenter.
@_spi(Internal) public protocol CheckpointEnginePresenterDelegate: AnyObject {

    func onCheckpointPaywallFinished(callID: String, outcome: CheckpointEnginePaywallOutcome)

}

/// Receives checkpoint engine events for conversion into the RevenueCatUI public listener API.
@_spi(Internal) public protocol CheckpointEngineListener: AnyObject {

    func onCheckpointHit(_ checkpoint: CheckpointInfo)
    func onCheckpointResolved(_ checkpoint: CheckpointInfo, result: CheckpointEngineResult)
    func onCheckpointPaywallFinished(
        _ checkpoint: CheckpointInfo,
        outcome: CheckpointEnginePaywallOutcome
    )

}
