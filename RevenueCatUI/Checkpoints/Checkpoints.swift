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

/// Core-owned checkpoint custom value, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointValue = RevenueCat.CheckpointValue
/// Core-owned checkpoint parameters, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointParams = RevenueCat.CheckpointParams

/// Information about a checkpoint that was hit.
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointInfo)
#endif
@_spi(Internal) public final class CheckpointInfo: NSObject, @unchecked Sendable {

    /// The identifier of the checkpoint that was hit.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
    public let identifier: String

    /// The parameters supplied when the checkpoint was hit.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
    public let params: CheckpointParams

    /// Creates checkpoint information for an identifier and its parameters.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
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
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointNoActionReason)
#endif
@_spi(Internal) public final class CheckpointNoActionReason: NSObject, @unchecked Sendable {

    /// The value identifying the reason.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
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
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        return (object as? CheckpointNoActionReason)?.value == self.value
    }

    public override var hash: Int { return self.value.hashValue }
    public override var description: String { return self.value }

}

/// Base class for the result of hitting a checkpoint.
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointResult)
#endif
@_spi(Internal) public class CheckpointResult: NSObject {

    /// Information about the checkpoint that produced this result.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
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
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointNoActionResult)
#endif
@_spi(Internal) public final class CheckpointNoActionResult: CheckpointResult {

    /// The reason no experience was served.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
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
@_spi(Internal) public protocol CheckpointListener: AnyObject {

    /// A checkpoint was hit, before evaluation.
    func onCheckpointHit(_ checkpoint: CheckpointInfo)
    /// The checkpoint completed and its result was returned.
    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult)

}

@_spi(Internal) public extension CheckpointListener {

    /// Default no-op implementation.
    func onCheckpointHit(_ checkpoint: CheckpointInfo) {}
    /// Default no-op implementation.
    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult) {}

}
