//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FooterHidingModifier.swift
//
//  Created by Nacho Soto on 8/9/23.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension View {

    func hideFooterContent(
        _ configuration: TemplateViewConfiguration,
        hide: Bool
    ) -> some View {
        return self.modifier(FooterHidingModifier(configuration: configuration,
                                                  hide: hide))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct FooterHidingModifier: ViewModifier {

    @State
    private var height: CGFloat = 10

    var configuration: TemplateViewConfiguration
    var hide: Bool

    func body(content: Content) -> some View {
        switch self.configuration.mode {
        case .fullScreen:
            // These modes don't support hiding the content
            content
                .padding(.vertical)

        case .footer:
            content

        case .condensedFooter:
            content
                .onHeightChange { if $0 > 0 { self.height = $0 } }
                .opacity(self.hide ? 0 : 1)
                .offset(
                    y: self.hide
                    ? self.height
                    : 0
                )
                .frame(height: self.hide ? 0 : nil)
                .blur(radius: self.hide ? Self.blurRadius : 0)
        }
    }

    private static let blurRadius: CGFloat = 20

}
