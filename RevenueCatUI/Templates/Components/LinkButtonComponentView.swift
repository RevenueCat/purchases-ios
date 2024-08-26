//
//  LinkButtonComponentView.swift
//
//
//  Created by James Borthwick on 2024-08-21.
//

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct LinkButtonComponentView: View {

    let locale: Locale
    let component: PaywallComponent.LinkButtonComponent

    var url: URL {
        component.url
    }

    var body: some View {
        Link(destination: url) {
            TextComponentView(locale: locale, component:component.textComponent)
                .cornerRadius(25)
        }

    }

}

#endif
