//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CompatibilityLabeledContent.swift
//
//
//  Created by Facundo Menzella on 14/1/25.
//

import SwiftUI

#if os(iOS)

/// A SwiftUI view that displays a label and content in a layout that adapts to the iOS version.
///
/// This view is designed to be compatible with both iOS 16.0+ and earlier versions.
///
/// - Parameters:
///   - label: A closure that returns the label view, typically a `Text` or any other view.
///   - content: A closure that returns the content view
///
/// ## Usage:
/// ```swift
/// CompatibilityLabeledContent {
///     Text("Name:")
/// } content: {
///     Text("John Doe")
/// }
/// ```
///
/// ## Available Initializers:
/// - `init(_ label: String, content: @escaping () -> Content)` for easy usage with `String` labels.
/// - `init(_ label: String, content: String)` for cases where both the label and content are strings.
///
/// ## iOS 16.0 and higher:
/// Uses `LabeledContent` to display the label and content in a more advanced and consistent way.
///
/// ## Earlier OS versions:
/// Uses a simple `HStack` to display the label and content, ensuring backward compatibility.
///
/// ## Discussion:
/// Although the `label` is a closure that returns a view (`() -> Label`), it is **not marked with `@ViewBuilder`
/// intentionally** for backwards compatibility.
///
/// If you need to pass multiple views in the label, you can still compose them manually using `HStack` or other layout
/// views in the closure passed to `label`. For example:
/// ```swift
/// CompatibilityLabeledContent("Name") {
///     HStack {
///         Text("First Name")
///         Text("Last Name")
///     }
/// } content: {
///     Text("John Doe")
/// }
/// ```
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CompatibilityLabeledContent<Label: View, Content: View>: View {

    @ViewBuilder let label: () -> Label
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 16.0, *) {
            LabeledContent {
                content()
            } label: {
                label()
            }
        } else {
            HStack {
                label()

                Spacer()

                content()
            }
        }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CompatibilityLabeledContent where Label == Text {
    init(_ label: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = { Text(label) }
        self.content = content
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CompatibilityLabeledContent where Label == Text, Content == EmptyView {
    init(_ label: String) {
        self.label = { Text(label) }
        self.content = { EmptyView() }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CompatibilityLabeledContent where Label == Text, Content == Text {
    init(_ label: String, content: String) {
        self.label = { Text(label) }
        self.content = { Text(content) }
    }
}

#endif
