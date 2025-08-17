//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SlotComponentView.swift
//
//  Created by Josh Holtz on 8/15/25.

import Foundation
import RevenueCat
import SwiftUI

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

// Returns AnyView so we can store any SwiftUI view
public typealias ViewProvider = (String) -> AnyView
public typealias ViewOtherProvider = (PaywallComponent) -> AnyView

public final class ViewRegistry: ObservableObject {

    public static let shared = ViewRegistry()

    private var viewCallback: ViewProvider?

    private var otherCallback: [PaywallComponent.ComponentType: ViewOtherProvider] = [:]

    internal init() {}

    // Register a view-producing callback
    public func register<Content: View>(type: PaywallComponent.ComponentType, @ViewBuilder _ callback: @escaping (PaywallComponent) -> Content) {

        self.otherCallback[type] = { component in
            AnyView(callback(component))
        }
    }

    // Register a view-producing callback
    public func register<Content: View>(@ViewBuilder _ callback: @escaping (String) -> Content) {
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

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct SlotComponentView: View {

    @EnvironmentObject
    private var packageContext: PackageContext

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var paywallPromoOfferCache: PaywallPromoOfferCache

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    @EnvironmentObject
    private var viewRegistry: ViewRegistry

    let viewModel: SlotComponentViewModel

    var body: some View {
        self.viewModel.styles(
            state: self.componentViewState,
            condition: self.screenCondition,
            isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                package: self.packageContext.package
            ),
            isEligibleForPromoOffer: self.paywallPromoOfferCache.isMostLikelyEligible(
                for: self.packageContext.package
            )
        ) { style in
            self.viewRegistry.makeView(identifier: viewModel.identifier)
            // Style the carousel
            .size(style.size)
            .padding(style.padding)
            .padding(style.margin)
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct SlotComponentView_Previews: PreviewProvider {

    static let viewRegistry: ViewRegistry = {
        let vr = ViewRegistry()

        vr.register { identifier in
            Text("Preview Slot \(identifier)")
        }

        vr.register(type: .slotLottie) { component in
            Text("Lottie goes here")
        }

        return vr
    }()

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {

        // Default
        VStack {
            SlotComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    component: .init(identifier: "test_slot_1")
                )
            )
        }
        .environmentObject(viewRegistry)
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: 100, height: 100))
        .previewDisplayName("Default")

    }
}

#endif


#endif
