//
//  LinkButtonComponentView.swift
//
//
//  Created by James Borthwick on 2024-08-21.
//
// swiftlint:disable missing_docs

import Combine
import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class LinkButtonComponentViewModel: ObservableObject {

    let locale: Locale
    @Published private(set) var component: PaywallComponent.LinkButtonComponent
    let textComponentViewModel: TextComponentViewModel

    public var url: URL {
        component.url
    }
    public var textComponent: PaywallComponent.TextComponent {
        component.textComponent
    }

    init(locale: Locale,
         component: PaywallComponent.LinkButtonComponent,
         localization: [String: String],
         offering: Offering
    ) throws {
        try component.validateLocalizationIDs(using: localization)
        self.locale = locale
        self.component = component
        self.textComponentViewModel = try TextComponentViewModel(locale: locale,
                                                             localization: localization,
                                                             component: component.textComponent)

    }

}

#endif
