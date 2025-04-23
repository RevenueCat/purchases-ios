//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseButtonComponentView.swift
//
//  Created by Josh Holtz on 9/27/24.

import Foundation
import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PurchaseButtonComponentView: View {

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var packageContext: PackageContext

    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    private let viewModel: PurchaseButtonComponentViewModel

    internal init(viewModel: PurchaseButtonComponentViewModel) {
        self.viewModel = viewModel
    }

    /// Show activity indicator only if purchase action in purchase handler
    var showActivityIndicatorOverContent: Bool {
        guard let actionType = self.purchaseHandler.actionTypeInProgress else {
            return false
        }

        switch actionType {
        case .purchase:
            return true
        case .restore:
            return false
        }
    }

    /// Disable for any type of purchase handler action
    var shouldBeDisabled: Bool {
        return self.purchaseHandler.actionInProgress
    }

    var body: some View {
        AsyncButton {
            self.logIfInPreview(package: self.packageContext.package)

            guard !self.purchaseHandler.actionInProgress else { return }

            // WIP: Need to log warning if currently subscribed
            guard let selectedPackage = self.packageContext.package
                    //                    , selectedPackage.currentlySubscribed
            else {
                Logger.warning(Strings.product_already_subscribed)
                return
            }

            _ = try await self.purchaseHandler.purchase(package: selectedPackage)
        } label: {
            // Not passing an onDismiss - nothing in this stack should be able to dismiss
            StackComponentView(
                viewModel: viewModel.stackViewModel,
                onDismiss: {},
                showActivityIndicatorOverContent: self.showActivityIndicatorOverContent
            )
        }
        .applyIf(self.shouldBeDisabled) {
            $0.disabled(true)
                .opacity(0.35)
        }
    }

    /// Used to see purchasing information when using SwiftUI Previews
    private func logIfInPreview(package: Package?) {
        #if DEBUG
        let isInPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

        if isInPreview {
            print("Purchasing package: \(package?.identifier ?? "NOTHING")")
        }
        #endif
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PurchaseButtonComponentView_Previews: PreviewProvider {

    static var previews: some View {
        // Pill
        PurchaseButtonComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                component: .init(
                    stack: .init(components: [
                        // WIP: Intro offer state with "id_2",
                        .text(.init(
                            text: "id_1",
                            fontWeight: .bold,
                            color: .init(light: .hex("#ffffff")),
                            backgroundColor: .init(light: .hex("#ff0000")),
                            padding: .init(top: 10,
                                           bottom: 10,
                                           leading: 30,
                                           trailing: 30)
                        ))
                    ])
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Hello, world"),
                        "id_2": .string("Hello, world intro offer")
                    ]
                ),
                offering: Offering(identifier: "",
                                   serverDescription: "",
                                   availablePackages: [])
            )
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Pill")

        // Rounded Rectangle
        PurchaseButtonComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                component: .init(
                    stack: .init(
                        components: [
                            // WIP: Intro offer state with "id_2",
                            .text(.init(
                                text: "id_1",
                                fontWeight: .bold,
                                color: .init(light: .hex("#ffffff"))
                            ))
                        ],
                        backgroundColor: .init(light: .hex("#ff0000")),
                        padding: .init(top: 8,
                                       bottom: 8,
                                       leading: 8,
                                       trailing: 8),
                        shape: .rectangle(.init(topLeading: 8,
                                                topTrailing: 8,
                                                bottomLeading: 8,
                                                bottomTrailing: 8))
                    )
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Hello, world"),
                        "id_2": .string("Hello, world intro offer")
                    ]
                ),
                offering: Offering(identifier: "",
                                   serverDescription: "",
                                   availablePackages: [])
            )
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Rounded Rectangle")
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension PurchaseButtonComponentViewModel {

    convenience init(
        component: PaywallComponent.PurchaseButtonComponent,
        localizationProvider: LocalizationProvider,
        offering: Offering
    ) throws {
        let factory = ViewModelFactory()
        let stackViewModel = try factory.toStackViewModel(
            component: component.stack,
            packageValidator: factory.packageValidator,
            firstImageInfo: nil,
            localizationProvider: localizationProvider,
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
            offering: offering
        )

        self.init(
            stackViewModel: stackViewModel
        )
    }

}

#endif

#endif
