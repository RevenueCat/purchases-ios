//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation
@_spi(Internal) import RevenueCat

extension PaywallFixture {

    /// Both tiers deliberately put their billing tabs at the same structural position, with
    /// disjoint tab IDs and packages. Index-based view reuse must not carry one tier's state over.
    static func nestedBillingTabsComponentsData() -> PaywallComponentsData {
        let tiers = ["silver", "gold"]
        let periods = ["annual", "monthly"]
        var strings: PaywallComponent.LocalizationDictionary = [
            "selected": .string("Selected {{ product.price }}")
        ]

        func label(_ key: String, _ text: String) -> PaywallComponent {
            strings[key] = .string(text)
            return .text(.init(text: key, color: .init(light: .hex("#000000"))))
        }

        func control(_ ids: [String]) -> PaywallComponent.TabsComponent.TabControl {
            return .init(type: .buttons, stack: .init(
                components: ids.map { id in
                    .tabControlButton(.init(tabId: id, stack: .init(components: [
                        label(id, id.replacingOccurrences(of: "_", with: " ").capitalized)
                    ])))
                },
                dimension: .horizontal(.center, .center),
                spacing: 24
            ))
        }

        let tabs: PaywallComponent = .tabs(.init(
            control: control(tiers),
            tabs: tiers.map { tier in
                let billingIDs = periods.map { "\(tier)_\($0)" }
                let packagePrefix = tier == "gold" ? "tier_three" : "tier_two"
                let billing: PaywallComponent = .tabs(.init(
                    control: control(billingIDs),
                    tabs: periods.map { period in
                        let billingID = "\(tier)_\(period)"
                        let packageID = "\(packagePrefix)_\(period == "annual" ? "yearly" : "monthly")"
                        return .init(id: billingID, stack: .init(components: [
                            .tabControl(.init()),
                            .package(.init(
                                packageID: packageID,
                                isSelectedByDefault: true,
                                applePromoOfferProductCode: nil,
                                stack: .init(components: [
                                    label("\(billingID)_card", "\(billingID) {{ product.price }}")
                                ])
                            ))
                        ]))
                    },
                    defaultTabId: billingIDs[0]
                ))
                return .init(id: tier, stack: .init(components: [
                    .tabControl(.init()),
                    .stack(.init(components: [label("\(tier)_features", "\(tier.capitalized) features")],
                                 size: .init(width: .fill, height: .fixed(180)))),
                    .stack(.init(components: [billing]))
                ], spacing: 24))
            },
            defaultTabId: "gold"
        ))

        return .init(
            templateName: "fixture-nested-billing-tabs",
            assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(
                    components: [tabs, .text(.init(text: "selected", color: .init(light: .hex("#000000"))))],
                    size: .init(width: .fill, height: .fill),
                    spacing: 24,
                    padding: .init(top: 60, bottom: 24, leading: 16, trailing: 16)
                ),
                stickyFooter: nil,
                background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: ["en_US": strings],
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )
    }

}
