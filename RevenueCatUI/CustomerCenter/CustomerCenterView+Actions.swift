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

// MARK: - CustomerCenterView Extension

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CustomerCenterView {

    // MARK: - Typealias Declarations

    /// A closure used for notifying of restore initiation in the Customer Center.
    public typealias RestoreStartedHandler = @MainActor @Sendable () -> Void

    /// A closure used for notifying of restore failure in the Customer Center.
    public typealias RestoreFailedHandler = @MainActor @Sendable (_ error: Error) -> Void

    /// A closure used for notifying of restore completion in the Customer Center.
    public typealias RestoreCompletedHandler = @MainActor @Sendable (_ customerInfo: CustomerInfo) -> Void

    /// A closure used for notifying when showing manage subscriptions in the Customer Center.
    public typealias ShowingManageSubscriptionsHandler = @MainActor @Sendable () -> Void

    /// A closure used for notifying of refund request initiation in the Customer Center.
    public typealias RefundRequestStartedHandler = @MainActor @Sendable (_ productId: String) -> Void

    /// A closure used for notifying of refund request completion in the Customer Center.
    public typealias RefundRequestCompletedHandler = @MainActor @Sendable (_ status: RefundRequestStatus) -> Void

    /// A closure used for notifying when a feedback survey option is selected in the Customer Center.
    public typealias FeedbackSurveyCompletedHandler = @MainActor @Sendable (_ optionId: String) -> Void

    // MARK: - Preference Keys

    struct RestoreCounterPreferenceKey: PreferenceKey {
        static var defaultValue: UUID = UUID()
        static func reduce(value: inout UUID, nextValue: () -> UUID) {
            let next = nextValue()
            #if DEBUG
            print("DEBUG: ⚙️ Counter reduce - current: \(value), next: \(next)")
            #endif

            // Only update if it's different from the default UUID
            if next != UUID() {
                value = next
            }
        }
    }

    struct RestoreFailedPreferenceKey: PreferenceKey {
        static var defaultValue: NSError?
        static func reduce(value: inout NSError?, nextValue: () -> NSError?) {
            value = nextValue() ?? value
        }
    }

    struct RestoreCompletedPreferenceKey: PreferenceKey {
        static var defaultValue: CustomerInfo?
        static func reduce(value: inout CustomerInfo?, nextValue: () -> CustomerInfo?) {
            value = nextValue() ?? value
        }
    }

    struct ShowingManageSubscriptionsPreferenceKey: PreferenceKey {
        static var defaultValue: Bool = false
        static func reduce(value: inout Bool, nextValue: () -> Bool) {
            value = value || nextValue()
        }
    }

    struct RefundRequestStartedPreferenceKey: PreferenceKey {
        static var defaultValue: String?
        static func reduce(value: inout String?, nextValue: () -> String?) {
            value = nextValue() ?? value
        }
    }

    struct RefundRequestCompletedPreferenceKey: PreferenceKey {
        static var defaultValue: RefundRequestStatus?
        static func reduce(value: inout RefundRequestStatus?, nextValue: () -> RefundRequestStatus?) {
            value = nextValue() ?? value
        }
    }

    struct FeedbackSurveyCompletedPreferenceKey: PreferenceKey {
        static var defaultValue: String?
        static func reduce(value: inout String?, nextValue: () -> String?) {
            value = nextValue() ?? value
        }
    }

    // MARK: - View Modifiers

    fileprivate struct OnRestoreFailedModifier: ViewModifier {
        let handler: RestoreFailedHandler

        func body(content: Content) -> some View {
            content
                .onPreferenceChange(RestoreFailedPreferenceKey.self) { error in
                    if let error {
                        self.handler(error)
                    }
                }
        }
    }

    fileprivate struct OnRestoreCompletedModifier: ViewModifier {
        let handler: RestoreCompletedHandler

        func body(content: Content) -> some View {
            content
                .onPreferenceChange(RestoreCompletedPreferenceKey.self) { customerInfo in
                    if let customerInfo {
                        self.handler(customerInfo)
                    }
                }
        }
    }

    fileprivate struct OnShowingManageSubscriptionsModifier: ViewModifier {
        let handler: ShowingManageSubscriptionsHandler

        func body(content: Content) -> some View {
            content
                .onPreferenceChange(ShowingManageSubscriptionsPreferenceKey.self) { isShowing in
                    if isShowing {
                        self.handler()
                    }
                }
        }
    }

    fileprivate struct OnRefundRequestStartedModifier: ViewModifier {
        let handler: RefundRequestStartedHandler

        func body(content: Content) -> some View {
            content
                .onPreferenceChange(RefundRequestStartedPreferenceKey.self) { productId in
                    if let productId {
                        self.handler(productId)
                    }
                }
        }
    }

    fileprivate struct OnRefundRequestCompletedModifier: ViewModifier {
        let handler: RefundRequestCompletedHandler

        func body(content: Content) -> some View {
            content
                .onPreferenceChange(RefundRequestCompletedPreferenceKey.self) { status in
                    if let status {
                        self.handler(status)
                    }
                }
        }
    }

    fileprivate struct OnFeedbackSurveyCompletedModifier: ViewModifier {
        let handler: FeedbackSurveyCompletedHandler

        func body(content: Content) -> some View {
            content
                .onPreferenceChange(FeedbackSurveyCompletedPreferenceKey.self) { optionId in
                    if let optionId {
                        self.handler(optionId)
                    }
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
        _ handler: @escaping CustomerCenterView.RestoreStartedHandler
    ) -> some View {
        return self.onPreferenceChange(CustomerCenterView.RestoreCounterPreferenceKey.self) { counter in
                    // Only trigger handler when counter is positive (> 0)
                    // This prevents the initial event when the view loads
                    print("onPreferenceChange counter: \(counter)")
                    handler()
                }
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
        _ handler: @escaping CustomerCenterView.RestoreFailedHandler
    ) -> some View {
        return self.modifier(CustomerCenterView.OnRestoreFailedModifier(handler: handler))
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
        _ handler: @escaping CustomerCenterView.RestoreCompletedHandler
    ) -> some View {
        return self.modifier(CustomerCenterView.OnRestoreCompletedModifier(handler: handler))
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
        _ handler: @escaping CustomerCenterView.ShowingManageSubscriptionsHandler
    ) -> some View {
        return self.modifier(CustomerCenterView.OnShowingManageSubscriptionsModifier(handler: handler))
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
        _ handler: @escaping CustomerCenterView.RefundRequestStartedHandler
    ) -> some View {
        return self.modifier(CustomerCenterView.OnRefundRequestStartedModifier(handler: handler))
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
        _ handler: @escaping CustomerCenterView.RefundRequestCompletedHandler
    ) -> some View {
        return self.modifier(CustomerCenterView.OnRefundRequestCompletedModifier(handler: handler))
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
        _ handler: @escaping CustomerCenterView.FeedbackSurveyCompletedHandler
    ) -> some View {
        return self.modifier(CustomerCenterView.OnFeedbackSurveyCompletedModifier(handler: handler))
    }
}
