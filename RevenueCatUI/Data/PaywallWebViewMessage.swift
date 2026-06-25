//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallWebViewMessage.swift

import Foundation

#if !os(tvOS) // For Paywalls V2

/// A validated message sent from a Paywalls V2 `web_view` component to your app.
///
/// Messages are delivered to the handler registered with `View/onPaywallWebViewMessage(_:)`.
/// The SDK only delivers messages that pass validation: the envelope is well-formed, the
/// ``componentID`` matches the `web_view` component's identifier, and all values are JSON-compatible.
///
/// The known message types are:
/// - `"rc:step-loaded"`: the web content finished loading. No additional fields.
/// - `"rc:step-complete"`: the web flow completed. ``responses`` carries the collected values.
/// - `"rc:request-variables"`: the web content is asking for variables. The SDK automatically
///   replies with SDK-managed and paywall custom variables; your handler may send additional ones.
/// - `"rc:error"`: the web content reported an error described by ``error``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct PaywallWebViewMessage: Sendable, Equatable {

    /// The identifier of the `web_view` component that produced this message. Matches the
    /// component's `id` in the paywall configuration.
    public let componentID: String

    /// The message type, e.g. `"rc:step-complete"`. Exposed as a string so new message types
    /// can be introduced without a source-breaking change for consumers.
    public let type: String

    /// The responses collected by the web flow. Only populated for `"rc:step-complete"` messages.
    public let responses: [String: PaywallWebViewValue]?

    /// The error reported by the web content. Only populated for `"rc:error"` messages.
    public let error: String?

    /// Creates a message. Intended for SDK and test use; app code receives instances via the
    /// message handler rather than constructing them.
    public init(
        componentID: String,
        type: String,
        responses: [String: PaywallWebViewValue]? = nil,
        error: String? = nil
    ) {
        self.componentID = componentID
        self.type = type
        self.responses = responses
        self.error = error
    }

}

#endif
