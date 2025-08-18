//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ViewRegistry.swift
//
//  Created by Josh Holtz on 8/18/25.

import Combine
import RevenueCat
import SwiftUI

/// A plugin that can register custom UI components with PurchasesUI.
public protocol PurchasesUIPlugin: Equatable {
    /// Unique identifier for this plugin.
    var id: String { get }

    /// Register the plugin's custom UI components.
    func register()
}

/// Main entry point for registering custom UI components and plugins with RevenueCatUI.
public enum PurchasesUI {

    /// Register a custom view for a specific paywall component type (Internal SPI).
    @_spi(Internal) public static func register<Content: View>(
        type: PaywallComponent.ComponentType,
        @ViewBuilder _ callback: @escaping (PaywallComponent) -> Content
    ) {
        ViewRegistry.shared.register(type: type, callback)
    }

    /// Register multiple plugins at once.
    /// ```swift
    /// PurchasesUI.register([PurchasesUI.Lottie])
    /// ```
    public static func register(_ plugins: [any PurchasesUIPlugin]) {
        plugins.forEach { $0.register() }
    }

    /// Register a single plugin.
    /// ```swift
    /// PurchasesUI.register(PurchasesUI.Lottie)
    /// ```
    public static func register(_ plugin: any PurchasesUIPlugin) {
        plugin.register()
    }

    /// Register a custom view builder for slot components (Internal SPI).
    @_spi(Internal) public static func register<Content: View>(@ViewBuilder _ callback: @escaping (String) -> Content) {
        ViewRegistry.shared.register(callback)
    }

}

// Returns AnyView so we can store any SwiftUI view
private typealias ViewProvider = (String) -> AnyView
private typealias ViewOtherProvider = (PaywallComponent) -> AnyView

final class ViewRegistry: ObservableObject {

    static let shared = ViewRegistry()

    private var viewCallback: ViewProvider?

    private var otherCallback: [PaywallComponent.ComponentType: ViewOtherProvider] = [:]

    internal init() {}

    // Register a view-producing callback
    func register<Content: View>(
        type: PaywallComponent.ComponentType,
        @ViewBuilder _ callback: @escaping (PaywallComponent) -> Content
    ) {

        self.otherCallback[type] = { component in
            AnyView(callback(component))
        }
    }

    // Register a view-producing callback
    func register<Content: View>(@ViewBuilder _ callback: @escaping (String) -> Content) {
        self.viewCallback = { id in
            AnyView(callback(id))
        }
    }

    // Build the view; safe fallback wrapped as AnyView
    func makeView(identifier: String) -> AnyView {
        viewCallback?(identifier) ?? AnyView(EmptyView())
    }

    func makeView(component: PaywallComponent) -> AnyView {
        self.otherCallback[component.type]?(component) ?? AnyView(EmptyView())
    }

}

private extension PaywallComponent {

    var type: PaywallComponent.ComponentType {
        switch self {
        case .text:
            return .text
        case .image:
            return .image
        case .icon:
            return .icon
        case .stack:
            return .stack
        case .button:
            return .button
        case .package:
            return .package
        case .purchaseButton:
            return .purchaseButton
        case .stickyFooter:
            return .stickyFooter
        case .timeline:
            return .timeline
        case .tabs:
            return .tabs
        case .tabControl:
            return .tabControl
        case .tabControlButton:
            return .tabControlButton
        case .tabControlToggle:
            return .tabControlToggle
        case .carousel:
            return .carousel
        case .slot:
            return .slot
        case .slotLottie:
            return .slotLottie
        }
    }

}
