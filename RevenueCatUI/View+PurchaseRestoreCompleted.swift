//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  View+PurchaseRestoreCompleted.swift
//  
//  Created by Nacho Soto on 7/31/23.

import RevenueCat
import SwiftUI

import StoreKit

// swiftlint:disable file_length

/// A closure used for notifying of purchase or restore completion.
public typealias PurchaseOrRestoreCompletedHandler = @MainActor @Sendable (CustomerInfo) -> Void

/// A closure used for notifying of purchase completion.
public typealias PurchaseCompletedHandler = @MainActor @Sendable (_ transaction: StoreTransaction?,
                                                                  _ customerInfo: CustomerInfo) -> Void

/// A closure used for notifying of purchase initiation.
@available(iOS, deprecated: 1, renamed: "PurchaseOfPackageStartedHandler")
@available(tvOS, deprecated: 1, renamed: "PurchaseOfPackageStartedHandler")
@available(watchOS, deprecated: 1, renamed: "PurchaseOfPackageStartedHandler")
@available(macOS, deprecated: 1, renamed: "PurchaseOfPackageStartedHandler")
@available(macCatalyst, deprecated: 1, renamed: "PurchaseOfPackageStartedHandler")
public typealias PurchaseStartedHandler = @MainActor @Sendable () -> Void

/// A closure used for notifying of purchase of a package initiation.
public typealias PurchaseOfPackageStartedHandler = @MainActor @Sendable (_ package: Package) -> Void

/// A closure used for notifying of purchase cancellation.
public typealias PurchaseCancelledHandler = @MainActor @Sendable () -> Void

/// A closure used to perform custom purchase logic implemented by your app.
/// - Parameters:
///   - package: The package to be purchased.
/// - Returns: A tuple indicating whether the user cancelled the operation and
/// any error encountered during the purchase process.
///   - userCancelled: `true` if the user cancelled the purchase; otherwise, `false`.
///   - error: An optional error that occurred during the purchase process, or `nil` if no error occurred.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public typealias PerformPurchase = @MainActor @Sendable (
    _ packageToPurchase: Package
) async -> (userCancelled: Bool, error: Error?)

/// A closure used to perform custom restore logic implemented by your app.
/// - Returns: A tuple indicating whether the restore operation was successful and
/// any error encountered during the process.
///   - success: `true` if the restore operation succeeded; otherwise, `false`.
///   - error: An optional error that occurred during the restore process, or `nil` if no error occurred.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public typealias PerformRestore = @MainActor @Sendable (
) async -> (success: Bool, error: Error?)

/// A closure used for notifying of failures during purchases or restores.
public typealias PurchaseFailureHandler = @MainActor @Sendable (NSError) -> Void

/// A closure used for notifying of restore initiation.
public typealias RestoreStartedHandler = @MainActor @Sendable () -> Void

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
extension View {

    /// Invokes the given closure when a purchase begins.
    /// Example:
    /// ```swift
    ///  @State
    ///  var body: some View {
    ///     PaywallView()
    ///         .onPurchaseStarted {
    ///             print("Purchase started")
    ///         }
    ///  }
    /// ```
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    @available(iOS, deprecated: 1, renamed: "onPurchaseStarted(handler:)")
    @available(tvOS, deprecated: 1, renamed: "onPurchaseStarted(handler:)")
    @available(watchOS, deprecated: 1, renamed: "onPurchaseStarted(handler:)")
    @available(macOS, deprecated: 1, renamed: "onPurchaseStarted(handler:)")
    @available(macCatalyst, deprecated: 1, renamed: "onPurchaseStarted(handler:)")
    public func onPurchaseStarted(
        _ handler: @escaping PurchaseStartedHandler
    ) -> some View {
        return self.modifier(OnPurchaseStartedModifier(handler: { _ in
            handler()
        }))
    }

    /// Invokes the given closure when a purchase of a package begins.
    /// Example:
    /// ```swift
    ///  @State
    ///  var body: some View {
    ///     PaywallView()
    ///         .onPurchaseStarted { package in
    ///             print("Purchase started for package: \(package)")
    ///         }
    ///  }
    /// ```
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    public func onPurchaseStarted(
        _ handler: @escaping PurchaseOfPackageStartedHandler
    ) -> some View {
        return self.modifier(OnPurchaseStartedModifier(handler: handler))
    }

    /// Invokes the given closure when a purchase is completed.
    /// The closure includes the `CustomerInfo` with unlocked entitlements.
    /// Example:
    /// ```swift
    ///  @State
    ///  private var displayPaywall: Bool = true
    ///
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayPaywall) {
    ///             PaywallView()
    ///                 .onPurchaseCompleted { customerInfo in
    ///                     print("Purchase completed: \(customerInfo.entitlements)")
    ///                     self.displayPaywall = false
    ///                 }
    ///         }
    ///  }
    /// ```
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    public func onPurchaseCompleted(
        _ handler: @escaping PurchaseOrRestoreCompletedHandler
    ) -> some View {
        return self.modifier(OnPurchaseCompletedModifier(handler: handler))
    }

    /// Invokes the given closure when a purchase is completed.
    /// The closure includes the `CustomerInfo` with unlocked entitlements.
    /// Example:
    /// ```swift
    ///  @State
    ///  private var displayPaywall: Bool = true
    ///
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayPaywall) {
    ///             PaywallView()
    ///                 .onPurchaseCompleted { transaction, customerInfo in
    ///                     print("Purchase completed: \(customerInfo.entitlements)")
    ///                     self.displayPaywall = false
    ///                 }
    ///         }
    ///  }
    /// ```
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    public func onPurchaseCompleted(
        _ handler: @escaping PurchaseCompletedHandler
    ) -> some View {
        return self.modifier(OnPurchaseCompletedModifier(handler: handler))
    }

    /// Invokes the given closure when a purchase is cancelled.
    ///
    /// Example:
    /// ```swift
    ///  PaywallView()
    ///     .onPurchaseCancelled {
    ///         print("Purchase was cancelled")
    ///     }
    /// ```
    public func onPurchaseCancelled(
        _ handler: @escaping PurchaseCancelledHandler
    ) -> some View {
        return self.modifier(OnPurchaseCancelledModifier(handler: handler))
    }

    /// Invokes the given closure when a restore begins.
    /// Example:
    /// ```swift
    ///  @State
    ///  var body: some View {
    ///     PaywallView()
    ///         .onRestoreStarted {
    ///             print("Restore started")
    ///         }
    ///  }
    /// ```
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    public func onRestoreStarted(
        _ handler: @escaping RestoreStartedHandler
    ) -> some View {
        return self.modifier(OnRestoreStartedModifier(handler: handler))
    }

    /// Invokes the given closure when restore purchases is completed.
    /// The closure includes the `CustomerInfo` after the process is completed.
    /// Example:
    /// ```swift
    ///  @State
    ///  private var displayPaywall: Bool = true
    ///
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayPaywall) {
    ///             PaywallView()
    ///                 .onRestoreCompleted { customerInfo in
    ///                     if !customerInfo.entitlements.active.isEmpty {
    ///                         self.displayPaywall = false
    ///                     }
    ///                 }
    ///         }
    ///  }
    /// ```
    ///
    /// - Warning: Receiving a ``CustomerInfo``does not imply that the user has any entitlements,
    /// simply that the process was successful. You must verify the ``CustomerInfo/entitlements``
    /// to confirm that they are active.
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    public func onRestoreCompleted(
        _ handler: @escaping PurchaseOrRestoreCompletedHandler
    ) -> some View {
        return self.modifier(OnRestoreCompletedModifier(handler: handler))
    }

    /// Invokes the given closure when an error is produced during a purchase.
    /// Example:
    /// ```swift
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayPaywall) {
    ///             PaywallView()
    ///                 .onPurchaseFailure { error in
    ///                     print("Error purchasing: \(error)")
    ///                 }
    ///         }
    ///  }
    /// ```
    public func onPurchaseFailure(
        _ handler: @escaping PurchaseFailureHandler
    ) -> some View {
        return self.modifier(PurchaseFailureModifier(handler: handler))
    }

    /// Invokes the given closure when an error is produced during restore purchases.
    /// Example:
    /// ```swift
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayPaywall) {
    ///             PaywallView()
    ///                 .onRestoreFailure { error in
    ///                     print("Error restoring purchases: \(error)")
    ///                 }
    ///         }
    ///  }
    /// ```
    public func onRestoreFailure(
        _ handler: @escaping PurchaseFailureHandler
    ) -> some View {
        return self.modifier(RestoreFailureModifier(handler: handler))
    }

    /// Invokes the given closure when the paywall is meant to be dismissed. This closure will be called:
    /// - When a purchase is completed.
    /// - Whenever the close button is pressed.
    /// Example:
    /// ```swift
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayPaywall) {
    ///             PaywallView()
    ///                 .onRequestedDismissal {
    ///                     self.dismiss()
    ///                 }
    ///         }
    ///  }
    /// ```
    public func onRequestedDismissal(_ action: @escaping (() -> Void)) -> some View {
        self.environment(\.onRequestedDismissal, action)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct OnPurchaseStartedModifier: ViewModifier {

    let handler: PurchaseOfPackageStartedHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(PurchaseInProgressPreferenceKey.self) { package in
                if let package {
                    self.handler(package)
                }
            }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct OnPurchaseCompletedModifier: ViewModifier {

    let handler: PurchaseCompletedHandler

    init(handler: @escaping PurchaseOrRestoreCompletedHandler) {
        self.handler = { _, customerInfo in handler(customerInfo) }
    }

    init(handler: @escaping PurchaseCompletedHandler) {
        self.handler = handler
    }

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(PurchasedResultPreferenceKey.self) { result in
                if let result, !result.userCancelled {
                    self.handler(result.transaction, result.customerInfo)
                }
            }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct OnPurchaseCancelledModifier: ViewModifier {

    let handler: PurchaseCancelledHandler

    init(handler: @escaping PurchaseCancelledHandler) {
        self.handler = handler
    }

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(PurchasedResultPreferenceKey.self) { result in
                if let result, result.userCancelled {
                    self.handler()
                }
            }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct OnRestoreStartedModifier: ViewModifier {

    let handler: RestoreStartedHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(RestoreInProgressPreferenceKey.self) { inProgress in
                if inProgress {
                    self.handler()
                }
            }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct OnRestoreCompletedModifier: ViewModifier {

    let handler: PurchaseOrRestoreCompletedHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(RestoredCustomerInfoPreferenceKey.self) { customerInfo in
                if let customerInfo {
                    self.handler(customerInfo)
                }
            }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PurchaseFailureModifier: ViewModifier {

    let handler: PurchaseFailureHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(PurchaseErrorPreferenceKey.self) { error in
                if let error {
                    self.handler(error)
                }
            }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct RestoreFailureModifier: ViewModifier {

    let handler: PurchaseFailureHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(RestoreErrorPreferenceKey.self) { error in
                if let error {
                    self.handler(error)
                }
            }
    }

}
