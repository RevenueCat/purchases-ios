//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterNavigationOptions.swift
//
//  Created by Facundo Menzella on 17/1/25.

/// Options for configuring the navigation behavior in the Customer Center.
///
/// This struct allows customization of navigation behavior, including the use of modern or legacy navigation systems,
/// whether to push onto an existing navigation stack, and whether to display a close button in the toolbar.
public struct CustomerCenterNavigationOptions {

    /// Indicates whether the modern iOS 16+ navigation system (`NavigationStack` with `.navigationDestination`)
    /// should be used instead of the legacy navigation system (`NavigationLink` with `NavigationView`).
    /// - `true` (default): Use `NavigationStack` for navigation.
    /// - `false`: Fall back to using `NavigationLink` for compatibility with older iOS versions.
    public let usesNavigationStack: Bool

    /// Specifies whether the current view should push its destination onto an existing navigation stack or
    /// wrap the destination content in its own navigation stack.
    /// - `true`: The destination is pushed onto the existing navigation stack, preserving navigation context.
    /// - `false` (default): The destination content is wrapped in a new `NavigationStack`.
    public let usesExistingNavigation: Bool

    /// Controls whether a close button should be displayed in the toolbar.
    /// - `true` (default): Displays a close button in the toolbar.
    /// - `false`: Does not display a close button, avoiding redundancy with the back button in a stacked navigation.
    public let shouldShowCloseButton: Bool

    /// A custom handler to execute when closing the Customer Center from the close button in the navigation bar.
    ///
    /// `onCloseHandler` allows developers to define a custom method for handling the dismissal of
    /// the Customer Center. This is useful in cases where the default SwiftUI dismissal (`@Environment(\.dismiss)`)
    /// is insufficient, such as when integrating with hybrid frameworks.
    ///
    /// If provided, this closure is called instead of the default dismissal behavior, giving the developer
    /// full control over the dismissal process.
    ///
    /// - Example Usage in SwiftUI:
    /// ```swift
    /// let options = CustomerCenterNavigationOptions(onCloseHandler: {
    ///     dismiss()
    /// })
    /// ```
    ///
    public let onCloseHandler: (() -> Void)?

    /// Initializes a new instance of `CustomerCenterNavigationOptions`.
    ///
    /// - Parameters:
    ///   - usesNavigationStack: Whether to use the modern iOS 16+ `NavigationStack` system. Defaults to `true`.
    ///   - usesExistingNavigation: Whether to push onto an existing navigation stack. Defaults to `false`.
    ///   - shouldShowCloseButton: Whether to display a close button in the toolbar. Defaults to `true`.
    ///   - onCloseHandler: Custom handler to be called when tapping on the close button. When set to `nil`,
    ///   environment `dismiss` is called
    public init(
        usesNavigationStack: Bool = true,
        usesExistingNavigation: Bool = false,
        shouldShowCloseButton: Bool = true,
        onCloseHandler: (() -> Void)? = nil
    ) {
        self.usesNavigationStack = usesNavigationStack
        self.usesExistingNavigation = usesExistingNavigation
        self.shouldShowCloseButton = shouldShowCloseButton
        self.onCloseHandler = onCloseHandler
    }
}

public extension CustomerCenterNavigationOptions {

    /// The default configuration for `CustomerCenterNavigationOptions`.
    ///
    /// - `usesNavigationStack`: `true` (default to modern navigation).
    /// - `usesExistingNavigation`: `false` (wraps content in a new navigation stack by default).
    /// - `shouldShowCloseButton`: `true` (displays a close button by default).
    /// - `onCloseHandler`: `nil` (environment dismiss is used instead when showing the close button).
    static let `default` = CustomerCenterNavigationOptions()
}
