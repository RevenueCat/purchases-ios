//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TextComponentView.swift
//
//  Created by Josh Holtz on 6/11/24.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TextComponentView: View {

    let locale: Locale
    let component: PaywallComponent.TextComponent

    var body: some View {
        Text(getLocalization(locale, component.text))
            .font(.custom(component.fontFamily,
                          size: UIFont.preferredFont(forTextStyle: component.textStyle.font).pointSize))
            .multilineTextAlignment(component.horizontalAlignment.textAlignment)
            .foregroundStyle(
                (try? PaywallColor(stringRepresentation: component.color.light).underlyingColor) ?? Color.clear
            )
            .padding(.top, component.padding.top)
            .padding(.bottom, component.padding.bottom)
            .padding(.leading, component.padding.leading)
            .padding(.trailing, component.padding.trailing)
            .background(self.backgroundColor)
    }

    var backgroundColor: Color? {
        if let thing = component.backgroundColor?.light {
            return (try? PaywallColor(stringRepresentation: thing).underlyingColor) ?? Color.clear
        }
        return nil
    }

}

#endif
