//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  View+CustomerCenterActions.swift
//  
//  Created by Cesar de la Vega on 2024-06-17.

import RevenueCat
import SwiftUI

// MARK: - Typealias Declarations

/// A closure used for notifying of restore initiation in the Customer Center.
public typealias CustomerCenterRestoreStartedHandler = @MainActor @Sendable () -> Void

/// A closure used for notifying of restore failure in the Customer Center.
public typealias CustomerCenterRestoreFailedHandler = @MainActor @Sendable (_ error: Error) -> Void

/// A closure used for notifying of restore completion in the Customer Center.
public typealias CustomerCenterRestoreCompletedHandler = @MainActor @Sendable (_ customerInfo: CustomerInfo) -> Void

/// A closure used for notifying when showing manage subscriptions in the Customer Center.
public typealias CustomerCenterShowingManageSubscriptionsHandler = @MainActor @Sendable () -> Void

/// A closure used for notifying of refund request initiation in the Customer Center.
public typealias CustomerCenterRefundRequestStartedHandler = @MainActor @Sendable (_ productId: String) -> Void

/// A closure used for notifying of refund request completion in the Customer Center.
public typealias CustomerCenterRefundRequestCompletedHandler = @MainActor @Sendable (_ status: RefundRequestStatus) -> Void

/// A closure used for notifying when a feedback survey option is selected in the Customer Center.
public typealias CustomerCenterFeedbackSurveyCompletedHandler = @MainActor @Sendable (_ optionId: String) -> Void

// MARK: - Preference Keys

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterRestoreStartedPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterRestoreFailedPreferenceKey: PreferenceKey {
    static var defaultValue: NSError?
    static func reduce(value: inout NSError?, nextValue: () -> NSError?) {
        value = nextValue() ?? value
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterRestoreCompletedPreferenceKey: PreferenceKey {
    static var defaultValue: CustomerInfo?
    static func reduce(value: inout CustomerInfo?, nextValue: () -> CustomerInfo?) {
        value = nextValue() ?? value
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterShowingManageSubscriptionsPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterRefundRequestStartedPreferenceKey: PreferenceKey {
    static var defaultValue: String?
    static func reduce(value: inout String?, nextValue: () -> String?) {
        value = nextValue() ?? value
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterRefundRequestCompletedPreferenceKey: PreferenceKey {
    static var defaultValue: RefundRequestStatus?
    static func reduce(value: inout RefundRequestStatus?, nextValue: () -> RefundRequestStatus?) {
        value = nextValue() ?? value
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterFeedbackSurveyCompletedPreferenceKey: PreferenceKey {
    static var defaultValue: String?
    static func reduce(value: inout String?, nextValue: () -> String?) {
        value = nextValue() ?? value
    }
}

// MARK: - View Modifiers

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct OnCustomerCenterRestoreStartedModifier: ViewModifier {
    let handler: CustomerCenterRestoreStartedHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(CustomerCenterRestoreStartedPreferenceKey.self) { inProgress in
                if inProgress {
                    self.handler()
                }
            }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct OnCustomerCenterRestoreFailedModifier: ViewModifier {
    let handler: CustomerCenterRestoreFailedHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(CustomerCenterRestoreFailedPreferenceKey.self) { error in
                if let error {
                    self.handler(error)
                }
            }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct OnCustomerCenterRestoreCompletedModifier: ViewModifier {
    let handler: CustomerCenterRestoreCompletedHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(CustomerCenterRestoreCompletedPreferenceKey.self) { customerInfo in
                if let customerInfo {
                    self.handler(customerInfo)
                }
            }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct OnCustomerCenterShowingManageSubscriptionsModifier: ViewModifier {
    let handler: CustomerCenterShowingManageSubscriptionsHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(CustomerCenterShowingManageSubscriptionsPreferenceKey.self) { isShowing in
                if isShowing {
                    self.handler()
                }
            }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct OnCustomerCenterRefundRequestStartedModifier: ViewModifier {
    let handler: CustomerCenterRefundRequestStartedHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(CustomerCenterRefundRequestStartedPreferenceKey.self) { productId in
                if let productId {
                    self.handler(productId)
                }
            }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct OnCustomerCenterRefundRequestCompletedModifier: ViewModifier {
    let handler: CustomerCenterRefundRequestCompletedHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(CustomerCenterRefundRequestCompletedPreferenceKey.self) { status in
                if let status {
                    self.handler(status)
                }
            }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct OnCustomerCenterFeedbackSurveyCompletedModifier: ViewModifier {
    let handler: CustomerCenterFeedbackSurveyCompletedHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(CustomerCenterFeedbackSurveyCompletedPreferenceKey.self) { optionId in
                if let optionId {
                    self.handler(optionId)
                }
            }
    }
}

// MARK: - View Extensions

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension View {

    /// Invokes the given closure when a restore begins in the Customer Center.
    /// Example:
    /// ```swift
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayCustomerCenter) {
    ///             CustomerCenterView()
    ///                 .onCustomerCenterRestoreStarted {
    ///                     print("Customer Center restore started")
    ///                 }
    ///         }
    ///  }
    /// ```
    public func onCustomerCenterRestoreStarted(
        _ handler: @escaping CustomerCenterRestoreStartedHandler
    ) -> some View {
        return self.modifier(OnCustomerCenterRestoreStartedModifier(handler: handler))
    }

    /// Invokes the given closure when a restore fails in the Customer Center.
    /// Example:
    /// ```swift
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayCustomerCenter) {
    ///             CustomerCenterView()
    ///                 .onCustomerCenterRestoreFailed { error in
    ///                     print("Customer Center restore failed: \(error)")
    ///                 }
    ///         }
    ///  }
    /// ```
    public func onCustomerCenterRestoreFailed(
        _ handler: @escaping CustomerCenterRestoreFailedHandler
    ) -> some View {
        return self.modifier(OnCustomerCenterRestoreFailedModifier(handler: handler))
    }

    /// Invokes the given closure when a restore is completed in the Customer Center.
    /// Example:
    /// ```swift
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayCustomerCenter) {
    ///             CustomerCenterView()
    ///                 .onCustomerCenterRestoreCompleted { customerInfo in
    ///                     print("Customer Center restore completed: \(customerInfo)")
    ///                 }
    ///         }
    ///  }
    /// ```
    public func onCustomerCenterRestoreCompleted(
        _ handler: @escaping CustomerCenterRestoreCompletedHandler
    ) -> some View {
        return self.modifier(OnCustomerCenterRestoreCompletedModifier(handler: handler))
    }

    /// Invokes the given closure when showing manage subscriptions in the Customer Center.
    /// Example:
    /// ```swift
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayCustomerCenter) {
    ///             CustomerCenterView()
    ///                 .onCustomerCenterShowingManageSubscriptions {
    ///                     print("Customer Center showing manage subscriptions")
    ///                 }
    ///         }
    ///  }
    /// ```
    public func onCustomerCenterShowingManageSubscriptions(
        _ handler: @escaping CustomerCenterShowingManageSubscriptionsHandler
    ) -> some View {
        return self.modifier(OnCustomerCenterShowingManageSubscriptionsModifier(handler: handler))
    }

    /// Invokes the given closure when a refund request starts in the Customer Center.
    /// Example:
    /// ```swift
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayCustomerCenter) {
    ///             CustomerCenterView()
    ///                 .onCustomerCenterRefundRequestStarted { productId in
    ///                     print("Customer Center refund request started for product: \(productId)")
    ///                 }
    ///         }
    ///  }
    /// ```
    public func onCustomerCenterRefundRequestStarted(
        _ handler: @escaping CustomerCenterRefundRequestStartedHandler
    ) -> some View {
        return self.modifier(OnCustomerCenterRefundRequestStartedModifier(handler: handler))
    }

    /// Invokes the given closure when a refund request completes in the Customer Center.
    /// Example:
    /// ```swift
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayCustomerCenter) {
    ///             CustomerCenterView()
    ///                 .onCustomerCenterRefundRequestCompleted { status in
    ///                     print("Customer Center refund request completed with status: \(status)")
    ///                 }
    ///         }
    ///  }
    /// ```
    public func onCustomerCenterRefundRequestCompleted(
        _ handler: @escaping CustomerCenterRefundRequestCompletedHandler
    ) -> some View {
        return self.modifier(OnCustomerCenterRefundRequestCompletedModifier(handler: handler))
    }

    /// Invokes the given closure when a feedback survey option is selected in the Customer Center.
    /// Example:
    /// ```swift
    ///  var body: some View {
    ///     ContentView()
    ///         .sheet(isPresented: self.$displayCustomerCenter) {
    ///             CustomerCenterView()
    ///                 .onCustomerCenterFeedbackSurveyCompleted { optionId in
    ///                     print("Customer Center feedback survey completed with option: \(optionId)")
    ///                 }
    ///         }
    ///  }
    /// ```
    public func onCustomerCenterFeedbackSurveyCompleted(
        _ handler: @escaping CustomerCenterFeedbackSurveyCompletedHandler
    ) -> some View {
        return self.modifier(OnCustomerCenterFeedbackSurveyCompletedModifier(handler: handler))
    }
}
