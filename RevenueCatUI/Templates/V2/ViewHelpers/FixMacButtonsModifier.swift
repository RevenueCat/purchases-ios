//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FixMacButtonsModifier.swift
//
//  Created by Chris Vasselli on 2025/07/30.

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct FixMacButtonsModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
        // On Mac, if we don't specify a button style it defaults to using the macOS-style
        // push button, so we need to override this behavior and match the default iOS behavior, which
        // is effectively .borderless in most cases (there may be exceptions for usage in Lists, etc.)
        #if targetEnvironment(macCatalyst) || os(macOS)
        .buttonStyle(.borderless)
        #endif
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    func fixMacButtons() -> some View {
        self.modifier(FixMacButtonsModifier())
    }
}
