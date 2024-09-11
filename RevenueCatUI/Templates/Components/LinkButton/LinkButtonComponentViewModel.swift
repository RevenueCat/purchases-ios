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

    init(component: PaywallComponent.LinkButtonComponent,
         localizedStrings: PaywallComponent.LocalizationDictionary
    ) throws {
        self.component = component
        self.textComponentViewModel = try TextComponentViewModel(localizedStrings: localizedStrings,
                                                                 component: component.textComponent)
    }

    private func currentComponent(for selectionState: SelectionState) -> PaywallComponent.LinkButtonComponent {
        switch selectionState {
        case .selected:
            return component.selectedComponent ?? component
        case .unselected:
            return component
        }
    }

    func url(for selectionState: SelectionState) -> URL {
        currentComponent(for: selectionState).url
    }

}

#endif
