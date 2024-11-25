//
//  LinkButtonComponentView.swift
//
//
//  Created by James Borthwick on 2024-08-21.
//
// swiftlint:disable missing_docs

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class LinkButtonComponentViewModel {

    let textComponentViewModel: TextComponentViewModel
    private let component: PaywallComponent.LinkButtonComponent

    public var url: URL {
        component.url
    }
    public var textComponent: PaywallComponent.TextComponent {
        component.textComponent
    }

    init(component: PaywallComponent.LinkButtonComponent,
         localizationProvider: LocalizationProvider
    ) throws {
        self.component = component
        self.textComponentViewModel = try TextComponentViewModel(localizationProvider: localizationProvider,
                                                                 component: component.textComponent)
    }

}

#endif
