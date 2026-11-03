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

    static func carouselTabsComponentsData() -> PaywallComponentsData {
        let tabIDs = ["annual", "monthly"]
        let tabs: PaywallComponent = .tabs(.init(
            control: .init(
                type: .buttons,
                stack: .init(
                    components: tabIDs.map { tabID in
                        .tabControlButton(.init(tabId: tabID, stack: .init(components: [
                            .text(.init(text: tabID, color: .init(light: .hex("#000000"))))
                        ])))
                    },
                    dimension: .horizontal(.center, .center),
                    spacing: 24
                )
            ),
            tabs: tabIDs.map { tabID in
                .init(id: tabID, stack: .init(components: [
                    .tabControl(.init()),
                    .carousel(.init(
                        pages: (0..<3).map { page in
                            .init(
                                components: [.text(.init(
                                    text: "\(tabID)_\(page)",
                                    color: .init(light: .hex("#000000"))
                                ))],
                                size: .init(width: .fill, height: .fixed(180))
                            )
                        },
                        pagePeek: 0,
                        initialPageIndex: tabID == "monthly" ? 1 : 0,
                        loop: tabID == "monthly"
                    ))
                ]))
            },
            defaultTabId: "annual"
        ))

        var strings: PaywallComponent.LocalizationDictionary = [
            "annual": .string("Annual"),
            "monthly": .string("Monthly")
        ]
        for tabID in tabIDs {
            for page in 0..<3 {
                strings["\(tabID)_\(page)"] = .string("\(tabID.capitalized) page \(page)")
            }
        }

        return .init(
            templateName: "fixture-carousel-tabs",
            assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(
                    components: [tabs],
                    size: .init(width: .fill, height: .fill),
                    backgroundColor: .init(light: .hex("#ffffff")),
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
