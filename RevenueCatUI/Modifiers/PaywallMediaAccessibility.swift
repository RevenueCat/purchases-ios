//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallMediaAccessibility.swift
//
//  Created by Michael S. Muegel on 8/27/26.

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Removes paywall media from the accessibility tree, without changing how it draws. Paywall
    /// images and icons carry no accessibility metadata, so VoiceOver would only say "image".
    ///
    /// Do not "simplify" to `accessibilityHidden`: verified on device, it is disregarded on this
    /// subtree in every placement, and `accessibilityElement(children: .ignore)` leaves the
    /// wrapper focusable with nothing to say.
    func paywallDecorativeMedia() -> some View {
        self.accessibilityRepresentation { Color.clear }
    }

}
