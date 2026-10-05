//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CompatibilityInsetGroupedListStyle.swift
//
//  Created by Asier G. Morato on 14/9/26.

import SwiftUI

#if os(iOS) || os(macOS)

@available(iOS 15.0, macOS 13.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// The inset-grouped list style on iOS. macOS has no grouped list style, so its screens are
    /// grouped forms instead (see ``CompatibilityGroupedList``) and there is nothing to set.
    @ViewBuilder
    func compatibleInsetGroupedListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self
        #endif
    }

}

/// A `List` on iOS, and a grouped `Form` on macOS, which gives the same sections the inset,
/// grouped look of the Mac's System Settings that a macOS `List` has no style for.
@available(iOS 15.0, macOS 13.0, tvOS 15.0, watchOS 8.0, *)
struct CompatibilityGroupedList<Content: View>: View {

    @ViewBuilder let content: () -> Content

    var body: some View {
        #if os(macOS)
        Form(content: content)
            .formStyle(.grouped)
        #else
        List(content: content)
        #endif
    }

}

#endif
