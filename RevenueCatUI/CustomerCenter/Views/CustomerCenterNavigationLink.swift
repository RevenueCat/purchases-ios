//
//  CustomerCenterNavigationLink.swift
//  RevenueCat
//
//  Created by Facundo Menzella on 14/1/25.
//

import RevenueCat
import SwiftUI

#if os(iOS)

/// A view that provides a navigation link to ``CustomerCenterView`` with a customizable label.
///
/// This is the **preferred way** to integrate ``CustomerCenterView`` into your `NavigationView`,
/// ensuring proper navigation behavior by pre-setting navigation options.
///
/// ## Example Usage
/// ```swift
/// CustomerCenterNavigationLink {
///     HStack {
///         Image(systemName: "person.circle")
///         Text("Customer Center")
///     }
/// }
///
/// CustomerCenterNavigationLink(Text("Customer Center"))
/// ```
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct CustomerCenterNavigationLink<Label: View>: View {

    private let customerCenterActionHandler: CustomerCenterActionHandler?
    @ViewBuilder private let label: () -> Label

    /// Initializes the navigation link with a label view provided by a closure.
    ///
    /// Use this initializer when the label requires dynamic content or complex logic.
    ///
    /// Example:
    /// ```swift
    /// CustomerCenterNavigationLink {
    ///     HStack {
    ///         Image(systemName: "person.circle")
    ///         Text("Customer Center")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter label: A closure that returns the view to display as the navigation link’s label.
    public init(
        customerCenterActionHandler: CustomerCenterActionHandler? = nil,
        @ViewBuilder label: @escaping () -> Label) {
            self.customerCenterActionHandler = customerCenterActionHandler
            self.label = label
        }

    /// The content and behavior of the navigation link.
    public var body: some View {
        NavigationLink {
            CustomerCenterView(
                customerCenterActionHandler: customerCenterActionHandler,
                navigationOptions: CustomerCenterNavigationOptions(
                    usesNavigationStack: false,
                    usesExistingNavigation: true,
                    shouldShowCloseButton: false
                ))
        } label: {
            label()
        }
    }
}

#endif
