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

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ComponentsView: View {

    @Environment(\.safeAreaInsets)
    private var safeAreaInsets

    @Environment(\.overlaidHeaderHeight)
    private var overlaidHeaderHeight

    let componentViewModels: [PaywallComponentViewModel]
    /// When true, applies safe area top padding to all children except the first.
    /// Used for ZStacks where the first child is a hero image that bleeds into the safe area.
    private let pushNonFirstChildrenBelowSafeArea: Bool
    private let onDismiss: () -> Void
    private let defaultPackage: Package?

    init(
        componentViewModels: [PaywallComponentViewModel],
        pushNonFirstChildrenBelowSafeArea: Bool = false,
        onDismiss: @escaping () -> Void,
        defaultPackage: Package? = nil
    ) {
        self.componentViewModels = componentViewModels
        self.pushNonFirstChildrenBelowSafeArea = pushNonFirstChildrenBelowSafeArea
        self.onDismiss = onDismiss
        self.defaultPackage = defaultPackage
    }

    var body: some View {
        ForEach(Array(componentViewModels.enumerated()), id: \.offset) { index, item in
            view(for: item)
                .padding(
                    .top,
                    index > 0 && pushNonFirstChildrenBelowSafeArea
                        ? safeAreaInsets.top + overlaidHeaderHeight
                        : 0
                )
        }
    }

    @ViewBuilder
    // swiftlint:disable:next cyclomatic_complexity
    private func view(for item: PaywallComponentViewModel) -> some View {
        switch item {
        case .root(let viewModel):
            RootView(viewModel: viewModel, onDismiss: onDismiss, defaultPackage: defaultPackage)
        case .text(let viewModel):
            TextComponentView(viewModel: viewModel)
        case .image(let viewModel):
            ImageComponentView(viewModel: viewModel)
        case .icon(let viewModel):
            IconComponentView(viewModel: viewModel)
        case .stack(let viewModel):
            StackComponentView(
                viewModel: viewModel,
                onDismiss: onDismiss
            )
        case .button(let viewModel):
            ButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
        case .package(let viewModel):
            PackageComponentView(viewModel: viewModel, onDismiss: onDismiss)
        case .purchaseButton(let viewModel):
            PurchaseButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
        case .stickyFooter(let viewModel):
            StickyFooterComponentView(viewModel: viewModel)
        case .timeline(let viewModel):
            TimelineComponentView(viewModel: viewModel)
        case .tabs(let viewModel):
            TabsComponentView(viewModel: viewModel, onDismiss: onDismiss)
        case .tabControl(let viewModel):
            TabControlComponentView(viewModel: viewModel, onDismiss: onDismiss)
        case .tabControlButton(let viewModel):
            TabControlButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
        case .tabControlToggle(let viewModel):
            TabControlToggleComponentView(viewModel: viewModel, onDismiss: onDismiss)
        case .carousel(let viewModel):
            CarouselComponentView(viewModel: viewModel, onDismiss: onDismiss)
        case .video(let viewModel):
            VideoComponentView(viewModel: viewModel)
        case .countdown(let viewModel):
            CountdownComponentView(viewModel: viewModel, onDismiss: onDismiss)
        }
    }
}

#endif
