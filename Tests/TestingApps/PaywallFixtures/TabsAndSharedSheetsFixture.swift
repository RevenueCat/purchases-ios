//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsAndSharedSheetsFixture.swift
//

import Foundation
@_spi(Internal) import RevenueCat

extension PaywallFixture {

    /// Two tabs without inline packages share a root selection supplied by sheets with different defaults.
    static func tabsAndSharedSheetsComponentsData() -> PaywallComponentsData {
        var strings: PaywallComponent.LocalizationDictionary = [
            "none": .string("Selected package: none"),
            "monthly": .string("Selected package: Monthly"),
            "annual": .string("Selected package: Annual")
        ]

        func text(_ value: String) -> PaywallComponent {
            strings[value] = .string(value)
            return .text(.init(text: value, color: .init(light: .hex("#000000"))))
        }

        func button(_ title: String, action: PaywallComponent.ButtonComponent.Action) -> PaywallComponent {
            return .button(.init(action: action, stack: .init(
                components: [text(title)], padding: .init(top: 12, bottom: 12, leading: 12, trailing: 12)
            )))
        }

        func sheet(_ name: String, defaultPackageID: String) -> PaywallComponent.ButtonComponent.Sheet {
            return .init(
                id: name,
                name: name,
                stack: .init(components: [
                    text(name)
                ] + [("$rc_monthly", "Monthly"), ("$rc_annual", "Annual")].map { identifier, title in
                    .package(.init(
                        packageID: identifier,
                        isSelectedByDefault: identifier == defaultPackageID,
                        applePromoOfferProductCode: nil,
                        stack: .init(components: [text(title)])
                    ))
                } + [button("Close sheet", action: .navigateBack)],
                spacing: 16, backgroundColor: .init(light: .hex("#ffffff")),
                padding: .init(top: 24, bottom: 24, leading: 16, trailing: 16)),
                backgroundBlur: false,
                size: .init(width: .fill, height: .fit(nil))
            )
        }

        let sharedSheet = sheet("Shared plans", defaultPackageID: "$rc_monthly")
        let annualSheet = sheet("Annual plans", defaultPackageID: "$rc_annual")
        let tabs = PaywallComponent.tabs(.init(
            control: .init(type: .buttons, stack: .init(components: [
                .tabControlButton(.init(tabId: "overview", stack: .init(components: [text("Overview")]))),
                .tabControlButton(.init(tabId: "annual", stack: .init(components: [text("Annual plans")])))
            ], dimension: .horizontal(.center, .center), spacing: 24)),
            tabs: [
                .init(id: "overview", stack: .init(components: [.tabControl(.init())])),
                .init(id: "annual", stack: .init(components: [
                    .tabControl(.init()),
                    button("View annual plans", action: .navigateTo(destination: .sheet(sheet: annualSheet)))
                ]))
            ],
            defaultTabId: "overview"
        ))
        let selection = PaywallComponent.text(.init(
            text: "none",
            color: .init(light: .hex("#000000")),
            overrides: [
                .init(extendedConditions: [.selectedPackage(operator: .in, packages: ["$rc_monthly"])],
                      properties: .init(text: "monthly")),
                .init(extendedConditions: [.selectedPackage(operator: .in, packages: ["$rc_annual"])],
                      properties: .init(text: "annual"))
            ]
        ))
        let purchase = PaywallComponent.purchaseButton(.init(
            stack: .init(components: [text("Purchase selected · {{ product.price }}")]),
            action: .inAppCheckout, method: .inAppCheckout, name: nil
        ))

        return .init(
            templateName: "fixture-tabs-and-shared-sheets", assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(components: [
                    button("View shared plans", action: .navigateTo(destination: .sheet(sheet: sharedSheet))),
                    tabs, selection, purchase
                ], spacing: 24, padding: .init(top: 60, bottom: 24, leading: 16, trailing: 16)),
                stickyFooter: nil, background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: ["en_US": strings], revision: 1, defaultLocaleIdentifier: "en_US"
        )
    }

}
