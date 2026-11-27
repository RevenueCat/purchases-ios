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

    static func fillCarouselComponentsData(inScrollingStack: Bool) -> PaywallComponentsData {
        let fill = PaywallComponent.Size(width: .fill, height: .fill)
        func text(_ key: String) -> PaywallComponent {
            .text(.init(text: key, color: .init(light: .hex("#000000"))))
        }

        var pageComponents = [text("title")]
        if !inScrollingStack {
            pageComponents.append(.stack(.init(
                components: [
                    text("feature"),
                    .stack(.init(components: [], size: .init(width: .fill, height: .fixed(400)))),
                    text("last_feature")
                ],
                size: fill,
                overflow: .scroll
            )))
        }
        pageComponents.append(text("upgrade"))
        let page = PaywallComponent.StackComponent(
            components: pageComponents,
            dimension: .vertical(.center, .spaceBetween),
            size: fill
        )
        let carousel: PaywallComponent = .carousel(.init(size: fill, pages: [page]))
        let components: [PaywallComponent]
        if inScrollingStack {
            // Force the scroll view to propose an unspecified height to its content.
            components = [carousel, text("below"), .stack(.init(
                components: [],
                size: .init(width: .fill, height: .fixed(1500))
            ))]
        } else {
            components = [.stack(.init(components: [carousel], size: fill, overflow: .scroll))]
        }

        return .init(
            templateName: "fixture-fill-carousel",
            assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(
                    components: components,
                    dimension: .vertical(.center, .start),
                    size: .init(width: .fill, height: inScrollingStack ? .fit(nil) : .fixed(300)),
                    spacing: 0,
                    overflow: inScrollingStack ? .scroll : .default
                ),
                stickyFooter: nil,
                background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: ["en_US": [
                "title": .string("Plan features"),
                "feature": .string("First feature"),
                "last_feature": .string("Last feature"),
                "upgrade": .string("Upgrade"),
                "below": .string("Below carousel")
            ]],
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )
    }

}
