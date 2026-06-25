//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  View+PaywallWebViewMessage.swift

import SwiftUI

#if !os(tvOS) // For Paywalls V2

/// A wrapper for the Paywalls V2 `web_view` message handler.
///
/// Invoked with each validated message a `web_view` component sends, plus a
/// ``PaywallWebViewController`` for replying. The closure runs on the main actor; it is not
/// `Sendable` because the controller holds a reference to the underlying web view.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct PaywallWebViewMessageAction {

    private let action: @MainActor (PaywallWebViewMessage, PaywallWebViewController) -> Void

    /// Creates a new web view message action.
    /// - Parameter action: The closure invoked with each validated message and a controller for
    ///   sending messages back to the web content.
    public init(
        _ action: @escaping @MainActor (PaywallWebViewMessage, PaywallWebViewController) -> Void
    ) {
        self.action = action
    }

    @MainActor
    func callAsFunction(_ message: PaywallWebViewMessage, _ controller: PaywallWebViewController) {
        self.action(message, controller)
    }

}

// MARK: - Environment Key

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallWebViewMessageActionKey: EnvironmentKey {
    static let defaultValue: PaywallWebViewMessageAction? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    var paywallWebViewMessageAction: PaywallWebViewMessageAction? {
        get { self[PaywallWebViewMessageActionKey.self] }
        set { self[PaywallWebViewMessageActionKey.self] = newValue }
    }

}

// MARK: - View Modifier

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Invokes the given closure when a Paywalls V2 `web_view` component sends a message.
    ///
    /// The handler receives a validated ``PaywallWebViewMessage`` and a ``PaywallWebViewController``
    /// it can use to reply. Your app decides what to do with each message — the SDK does not
    /// automatically dismiss the paywall or start a purchase.
    ///
    /// Example:
    /// ```swift
    /// PaywallView(offering: offering)
    ///     .onPaywallWebViewMessage { message, controller in
    ///         switch message.type {
    ///         case "rc:step-complete":
    ///             let responses = message.responses
    ///             // App decides what to do: dismiss, navigate, log analytics, etc.
    ///
    ///         case "rc:request-variables":
    ///             controller.postVariables(
    ///                 componentID: message.componentID,
    ///                 variables: ["app_segment": .string("high_intent")]
    ///             )
    ///
    ///         case "rc:error":
    ///             // App can log/report the error via message.error.
    ///             break
    ///
    ///         default:
    ///             break
    ///         }
    ///     }
    /// ```
    ///
    /// - Note: For `"rc:request-variables"`, the SDK automatically replies with its SDK-managed
    ///   variables (`locale`) before invoking this handler, so you only need to send any
    ///   *additional* variables.
    public func onPaywallWebViewMessage(
        _ action: @escaping @MainActor (PaywallWebViewMessage, PaywallWebViewController) -> Void
    ) -> some View {
        self.environment(\.paywallWebViewMessageAction, PaywallWebViewMessageAction(action))
    }

}

#endif
