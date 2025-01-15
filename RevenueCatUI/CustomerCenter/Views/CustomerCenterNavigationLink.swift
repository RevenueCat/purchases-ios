//
//  CustomerCenterNavigationLink.swift
//  RevenueCat
//
//  Created by Facundo Menzella on 14/1/25.
//

import RevenueCat
import SwiftUI

/// A view that provides a navigation link to `CustomerCenterView` with a customizable label.
///
/// This is the **preferred way** to integrate `CustomerCenterView` into your `NavigationStack`,
/// ensuring proper navigation behavior by setting `isEmbededInNavigation` to `true`.
///
///
/// Example:
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

    @ViewBuilder let label: () -> Label

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
    public init(label: @escaping () -> Label) {
        self.label = label
    }

    /// The content and behavior of the navigation link.
    public var body: some View {
        NavigationLink {
            CustomerCenterView(isEmbeddedInNavigationStack: true)
        } label: {
            label()
        }
    }
}
