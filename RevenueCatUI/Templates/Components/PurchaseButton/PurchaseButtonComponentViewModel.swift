//
//  PurchaseButtonComponentView.swift
//
//
//  Created by James Borthwick on 2024-09-06.
//
// swiftlint:disable missing_docs

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class PurchaseButtonComponentViewModel {

    let textComponentViewModel: TextComponentViewModel
    private let component: PaywallComponent.PurchaseButtonComponent


    init(component: PaywallComponent.PurchaseButtonComponent,
         localizedStrings: PaywallComponent.LocalizationDictionary
    ) throws {
        self.component = component
        self.textComponentViewModel = try TextComponentViewModel(localizedStrings: localizedStrings,
                                                                 component: component.textComponent)
    }

    private func currentComponent(for selectionState: SelectionState) -> PaywallComponent.PurchaseButtonComponent {
        switch selectionState {
        case .selected:
            return component.selectedComponent ?? component
        case .unselected:
            return component
        }
    }

}

#endif
