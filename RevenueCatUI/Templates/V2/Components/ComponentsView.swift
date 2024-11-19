//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ComponentsView.swift
//
//  Created by Josh Holtz on 11/17/24.

import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ComponentsView: View {

    let componentViewModels: [PaywallComponentViewModel]
    private let onDismiss: () -> Void

    init(componentViewModels: [PaywallComponentViewModel], onDismiss: @escaping () -> Void) {
        self.componentViewModels = componentViewModels
        self.onDismiss = onDismiss
    }

    var body: some View {
        self.layoutComponents(self.componentViewModels)
    }

    @ViewBuilder
    func layoutComponents(_ componentViewModels: [PaywallComponentViewModel]) -> some View {
        ForEach(Array(componentViewModels.enumerated()), id: \.offset) { _, item in
            switch item {
            case .root(let viewModel):
                RootView(viewModel: viewModel, onDismiss: onDismiss)
            case .text(let viewModel):
                TextComponentView(viewModel: viewModel)
            case .image(let viewModel):
                ImageComponentView(viewModel: viewModel)
            case .spacer(let viewModel):
                SpacerComponentView(viewModel: viewModel)
            case .stack(let viewModel):
                StackComponentView(viewModel: viewModel, onDismiss: onDismiss)
            case .linkButton(let viewModel):
                LinkButtonComponentView(viewModel: viewModel)
            case .button(let viewModel):
                ButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
            case .package(let viewModel):
                PackageComponentView(viewModel: viewModel, onDismiss: onDismiss)
            case .purchaseButton(let viewModel):
                PurchaseButtonComponentView(viewModel: viewModel)
            case .stickyFooter(let viewModel):
                StickyFooterComponentView(viewModel: viewModel)
            }
        }
    }

}

#endif
