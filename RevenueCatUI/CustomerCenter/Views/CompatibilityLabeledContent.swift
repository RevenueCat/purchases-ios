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

/// A SwiftUI view for displaying a message about unavailable content
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CompatibilityLabeledContent<Label: View, Content: View>: View {

    let label: () -> Label
    let content: () -> Content

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
extension CompatibilityLabeledContent where Label == Text, Content == Text {
    init(_ label: String, content: String) {
        self.label = { Text(label) }
        self.content = { Text(content) }
    }
}

#endif
