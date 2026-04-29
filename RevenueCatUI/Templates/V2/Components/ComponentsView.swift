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
    /// When true, text components suppress their accessibilityIdentifier and are hidden from
    /// the accessibility tree. This prevents button label content from being exposed as separate
    /// accessible elements, which would prevent the button's own label from being shown.
    private let isInsideButtonLabel: Bool

    init(
        componentViewModels: [PaywallComponentViewModel],
        pushNonFirstChildrenBelowSafeArea: Bool = false,
        onDismiss: @escaping () -> Void,
        defaultPackage: Package? = nil,
        isInsideButtonLabel: Bool = false
    ) {
        self.componentViewModels = componentViewModels
        self.pushNonFirstChildrenBelowSafeArea = pushNonFirstChildrenBelowSafeArea
        self.onDismiss = onDismiss
        self.defaultPackage = defaultPackage
        self.isInsideButtonLabel = isInsideButtonLabel
    }

    var body: some View {
        ForEach(Array(componentViewModels.enumerated()), id: \.offset) { index, item in
            view(for: item)
                .padding(
                    .top,
                    index > 0 && pushNonFirstChildrenBelowSafeArea
                        ? max(safeAreaInsets.top, overlaidHeaderHeight)
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
                .applyIf(!isInsideButtonLabel) { view in
                    view.accessibilityIdentifier(viewModel.componentId ?? "text")
                }
                .accessibilityHidden(isInsideButtonLabel)
        case .image(let viewModel):
            ImageComponentView(viewModel: viewModel)
        case .icon(let viewModel):
            IconComponentView(viewModel: viewModel)
                .accessibilityLabel(viewModel.componentName)
                .accessibilityIdentifier(viewModel.componentId ?? viewModel.componentName)
        case .stack(let viewModel):
            StackComponentView(
                viewModel: viewModel,
                onDismiss: onDismiss,
                accessibilityLabel: isInsideButtonLabel
                    ? nil
                    : viewModel.component.name ?? viewModel.component.dimension.typeName,
                accessibilityIdentifier: isInsideButtonLabel
                    ? nil
                    : viewModel.component.id ?? "stack",
                isInsideButtonLabel: isInsideButtonLabel
            )
        case .button(let viewModel):
            ButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityIdentifier(viewModel.component.id ?? viewModel.id ?? "button")
        case .package(let viewModel):
            PackageComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityLabel(viewModel.componentName ?? "package")
                .accessibilityIdentifier(viewModel.componentId ?? "package")
                .accessibilityElement(children: .contain)
        case .purchaseButton(let viewModel):
            PurchaseButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
        case .stickyFooter(let viewModel):
            StickyFooterComponentView(viewModel: viewModel)
                .accessibilityLabel("sticky_footer")
                .accessibilityIdentifier(viewModel.component.id ?? "sticky_footer")
                .accessibilityElement(children: .contain)
        case .timeline(let viewModel):
            TimelineComponentView(viewModel: viewModel)
                .accessibilityLabel("timeline")
                .accessibilityIdentifier(viewModel.componentId ?? "timeline")
                .accessibilityElement(children: .contain)
        case .tabs(let viewModel):
            TabsComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityLabel(viewModel.name ?? "tabs")
                .accessibilityIdentifier(viewModel.componentId ?? "tabs")
                .accessibilityElement(children: .contain)
        case .tabControl(let viewModel):
            TabControlComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityLabel("tab_control")
                .accessibilityIdentifier(viewModel.component.id ?? "tab_control")
                .accessibilityElement(children: .contain)
        case .tabControlButton(let viewModel):
            TabControlButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityLabel(viewModel.component.name ?? "tab_control_button")
                .accessibilityIdentifier(viewModel.component.id ?? viewModel.component.tabId)
        case .tabControlToggle(let viewModel):
            TabControlToggleComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityLabel(viewModel.component.name ?? "tab_control_toggle")
                .accessibilityIdentifier(viewModel.component.id ?? "tab_control_toggle")
                .accessibilityElement(children: .contain)
        case .carousel(let viewModel):
            CarouselComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityLabel(viewModel.componentName ?? "carousel")
                .accessibilityIdentifier(viewModel.componentId ?? "carousel")
                .accessibilityElement(children: .contain)
        case .video(let viewModel):
            VideoComponentView(viewModel: viewModel)
                .accessibilityLabel(viewModel.componentName ?? "video")
                .accessibilityIdentifier(viewModel.componentId ?? "video")
                .accessibilityElement(children: .contain)
        case .countdown(let viewModel):
            CountdownComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityLabel(viewModel.component.name ?? "countdown")
                .accessibilityIdentifier(viewModel.component.id ?? "countdown")
                .accessibilityElement(children: .contain)
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallComponent.Dimension {
    var typeName: String {
        switch self {
        case .vertical: return "VStack"
        case .horizontal: return "HStack"
        case .zlayer: return "ZStack"
        }
    }
}

#endif
