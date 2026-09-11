//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallComponentViewModel.swift
//
//  Created by Josh Holtz on 11/7/24.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallComponentViewModel {

    case root(RootViewModel)
    case text(TextComponentViewModel)
    case image(ImageComponentViewModel)
    case icon(IconComponentViewModel)
    case stack(StackComponentViewModel)
    case button(ButtonComponentViewModel)
    case package(PackageComponentViewModel)
    case purchaseButton(PurchaseButtonComponentViewModel)
    case stickyFooter(StickyFooterComponentViewModel)
    case timeline(TimelineComponentViewModel)

    case tabs(TabsComponentViewModel)
    case tabControl(TabControlComponentViewModel)
    case tabControlButton(TabControlButtonComponentViewModel)
    case tabControlToggle(TabControlToggleComponentViewModel)

    case carousel(CarouselComponentViewModel)
    case video(VideoComponentViewModel)
    case countdown(CountdownComponentViewModel)
    case webView(WebViewComponentViewModel)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponentViewModel {

    var usesMinMaxSizing: Bool {
        switch self {
        case .root(let viewModel):
            return viewModel.stackViewModel.usesMinMaxSizing
        case .text(let viewModel):
            return viewModel.component.size.hasMinMaxSizing
                || viewModel.component.overrides?.contains {
                    $0.properties.size?.hasMinMaxSizing == true
                } == true
        case .image(let viewModel):
            return viewModel.component.size.hasMinMaxSizing
                || viewModel.component.overrides?.contains {
                    $0.properties.size?.hasMinMaxSizing == true
                } == true
        case .icon(let viewModel):
            return viewModel.component.size.hasMinMaxSizing
                || viewModel.component.overrides?.contains {
                    $0.properties.size?.hasMinMaxSizing == true
                } == true
        case .stack(let viewModel):
            return viewModel.usesMinMaxSizing
        case .button(let viewModel):
            return viewModel.stackViewModel.usesMinMaxSizing
        case .package(let viewModel):
            return viewModel.stackViewModel.usesMinMaxSizing
        case .purchaseButton(let viewModel):
            return viewModel.stackViewModel.usesMinMaxSizing
        case .stickyFooter(let viewModel):
            return viewModel.stackViewModel.usesMinMaxSizing
        case .timeline(let viewModel):
            return viewModel.component.size.hasMinMaxSizing
                || viewModel.component.overrides?.contains {
                    $0.properties.size?.hasMinMaxSizing == true
                } == true
        case .tabs(let viewModel):
            return viewModel.component.size.hasMinMaxSizing
                || viewModel.component.overrides?.contains {
                    $0.properties.size?.hasMinMaxSizing == true
                } == true
        case .tabControl:
            return false
        case .tabControlButton(let viewModel):
            return viewModel.stackViewModel.usesMinMaxSizing
        case .tabControlToggle:
            return false
        case .carousel(let viewModel):
            return viewModel.component.size?.hasMinMaxSizing == true
                || viewModel.component.overrides?.contains {
                    $0.properties.size?.hasMinMaxSizing == true
                } == true
        case .video(let viewModel):
            return viewModel.component.size.hasMinMaxSizing
                || viewModel.component.overrides?.contains {
                    $0.properties.size?.hasMinMaxSizing == true
                } == true
        case .countdown(let viewModel):
            return viewModel.countdownStackViewModel.usesMinMaxSizing
        case .webView(let viewModel):
            return viewModel.component.size.hasMinMaxSizing
        }
    }

    var componentSizeLayoutValue: ComponentSizeLayoutValue? {
        let size: PaywallComponent.Size
        switch self {
        case .root(let viewModel):
            return viewModel.stackViewModel.componentSizeLayoutValue
        case .text(let viewModel):
            size = viewModel.component.size
        case .image(let viewModel):
            size = viewModel.component.size
        case .icon(let viewModel):
            size = viewModel.component.size
        case .stack(let viewModel):
            return viewModel.componentSizeLayoutValue
        case .button(let viewModel):
            return viewModel.stackViewModel.componentSizeLayoutValue
        case .package(let viewModel):
            return viewModel.stackViewModel.componentSizeLayoutValue
        case .purchaseButton(let viewModel):
            return viewModel.stackViewModel.componentSizeLayoutValue
        case .stickyFooter(let viewModel):
            return viewModel.stackViewModel.componentSizeLayoutValue
        case .timeline(let viewModel):
            size = viewModel.component.size
        case .tabs(let viewModel):
            size = viewModel.component.size
        case .tabControl:
            return nil
        case .tabControlButton(let viewModel):
            return viewModel.stackViewModel.componentSizeLayoutValue
        case .tabControlToggle:
            return nil
        case .carousel(let viewModel):
            guard let carouselSize = viewModel.component.size else { return nil }
            size = carouselSize
        case .video(let viewModel):
            size = viewModel.component.size
        case .countdown(let viewModel):
            return viewModel.countdownStackViewModel.componentSizeLayoutValue
        case .webView(let viewModel):
            size = viewModel.component.size
        }
        return ComponentSizeLayoutValue(size)
    }

}

#endif
