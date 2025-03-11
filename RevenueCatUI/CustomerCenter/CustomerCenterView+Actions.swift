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

#if os(iOS)

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

    struct RestoreStartedPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<Bool>?
        static func reduce(value: inout UniqueWrapper<Bool>?, nextValue: () -> UniqueWrapper<Bool>?) {
            value = nextValue() ?? value
        }
    }

    struct RestoreFailedPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<NSError>?
        static func reduce(value: inout UniqueWrapper<NSError>?, nextValue: () -> UniqueWrapper<NSError>?) {
            value = nextValue() ?? value
        }
    }

    struct RestoreCompletedPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<CustomerInfo>?
        static func reduce(value: inout UniqueWrapper<CustomerInfo>?, nextValue: () -> UniqueWrapper<CustomerInfo>?) {
            value = nextValue() ?? value
        }
    }

    struct ShowingManageSubscriptionsPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<Bool>?
        static func reduce(value: inout UniqueWrapper<Bool>?, nextValue: () -> UniqueWrapper<Bool>?) {
            value = nextValue() ?? value
        }
    }

    struct RefundRequestStartedPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<String>?
        static func reduce(value: inout UniqueWrapper<String>?, nextValue: () -> UniqueWrapper<String>?) {
            value = nextValue() ?? value
        }
    }

    struct RefundRequestCompletedPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<(String, RefundRequestStatus)>?
        static func reduce(value: inout UniqueWrapper<(String, RefundRequestStatus)>?, nextValue: () -> UniqueWrapper<(String, RefundRequestStatus)>?) {
            value = nextValue() ?? value
        }
    }

    struct FeedbackSurveyCompletedPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<String>?
        static func reduce(value: inout UniqueWrapper<String>?, nextValue: () -> UniqueWrapper<String>?) {
            value = nextValue() ?? value
        }
    }

    // MARK: - View Modifiers

    fileprivate struct OnRestoreStartedModifier: ViewModifier {
        let handler: RestoreStartedHandler

        func body(content: Content) -> some View {
            content
                .onPreferenceChange(RestoreStartedPreferenceKey.self) { wrappedStarted in
                    if wrappedStarted?.value == true {
                        self.handler()
                    }
                }
        }
    }

    fileprivate struct OnRestoreFailedModifier: ViewModifier {
        let handler: RestoreFailedHandler

        func body(content: Content) -> some View {
            content
                .onPreferenceChange(CustomerCenterView.RestoreFailedPreferenceKey.self) { wrappedError in
                    if let error = wrappedError?.value {
                        self.handler(error)
                    }
                }
        }
    }

    fileprivate struct OnRestoreCompletedModifier: ViewModifier {
        let handler: RestoreCompletedHandler

        func body(content: Content) -> some View {
            content
                .onPreferenceChange(RestoreCompletedPreferenceKey.self) { wrappedCustomerInfo in
                    if let customerInfo = wrappedCustomerInfo?.value {
                        self.handler(customerInfo)
                    }
                }
        }
    }

    fileprivate struct OnShowingManageSubscriptionsModifier: ViewModifier {
        let handler: ShowingManageSubscriptionsHandler

        func body(content: Content) -> some View {
            content
                .onPreferenceChange(ShowingManageSubscriptionsPreferenceKey.self) { wrappedIsShowing in
                    if wrappedIsShowing?.value == true {
                        self.handler()
                    }
                }
        }
    }

    fileprivate struct OnRefundRequestStartedModifier: ViewModifier {
        let handler: RefundRequestStartedHandler

        func body(content: Content) -> some View {
            content
                .onPreferenceChange(RefundRequestStartedPreferenceKey.self) { wrappedProductId in
                    if let productId = wrappedProductId?.value {
                        self.handler(productId)
                    }
                }
        }
    }

    fileprivate struct OnRefundRequestCompletedModifier: ViewModifier {
        let handler: RefundRequestCompletedHandler

        func body(content: Content) -> some View {
            content
                .onPreferenceChange(RefundRequestCompletedPreferenceKey.self) { wrapped in
                    if let (_, status) = wrapped?.value {
                        self.handler(status)
                    }
                }
        }
    }

    fileprivate struct OnFeedbackSurveyCompletedModifier: ViewModifier {
        let handler: FeedbackSurveyCompletedHandler

        func body(content: Content) -> some View {
            content
                .onPreferenceChange(FeedbackSurveyCompletedPreferenceKey.self) { wrappedOptionId in
                    if let optionId = wrappedOptionId?.value {
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
        return self.modifier(CustomerCenterView.OnRestoreStartedModifier(handler: handler))
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

#endif
