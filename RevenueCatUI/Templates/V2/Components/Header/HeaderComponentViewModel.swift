//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HeaderComponentViewModel.swift
//
//  Created by Facundo Menzella on 02/04/2026.

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class HeaderComponentViewModel {

    let component: PaywallComponent.HeaderComponent
    let stackViewModel: StackComponentViewModel
    let firstItemIgnoresSafeArea: Bool

    init(
        component: PaywallComponent.HeaderComponent,
        stackViewModel: StackComponentViewModel,
        firstItemIgnoresSafeArea: Bool
    ) {
        self.component = component
        self.stackViewModel = stackViewModel
        self.firstItemIgnoresSafeArea = firstItemIgnoresSafeArea
    }

    /// Decorative stacks collapse with their buttons, but other header content remains in place.
    var buttonOnlyContentIdentifiers: Set<ObjectIdentifier>? {
        Self.buttonIdentifiers(in: self.stackViewModel)
    }

    private static func buttonIdentifiers(in stack: StackComponentViewModel) -> Set<ObjectIdentifier>? {
        guard stack.badgeViewModels.isEmpty else { return nil }
        var identifiers: Set<ObjectIdentifier> = []
        for viewModel in stack.viewModels {
            switch viewModel {
            case .button(let button):
                identifiers.insert(ObjectIdentifier(button))
            case .stack(let child):
                guard let children = Self.buttonIdentifiers(in: child) else { return nil }
                identifiers.formUnion(children)
            default:
                return nil
            }
        }
        return identifiers
    }

}

#endif
