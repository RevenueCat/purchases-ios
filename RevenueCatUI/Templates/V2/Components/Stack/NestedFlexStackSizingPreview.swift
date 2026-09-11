//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NestedFlexStackSizingPreview.swift
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if DEBUG && !os(tvOS) && ENABLE_PAYWALL_MIN_MAX_SIZING

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct NestedFlexStackSizing_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            nestedFlexStackPreview(
                title: "Outer vertical Fit(min: 280)",
                detail: "The blue row should touch the bottom edge.",
                component: verticalNestedFlexStack,
                localizedStrings: [
                    "vertical_inner_top": .string("Inner top"),
                    "vertical_inner_bottom": .string("Inner bottom"),
                    "vertical_outer_bottom": .string("Outer bottom")
                ]
            )
            .previewLayout(.fixed(width: 320, height: 390))
            .previewDisplayName("Nested Flex · Vertical")

            nestedFlexStackPreview(
                title: "Outer horizontal Fit(min: 320)",
                detail: "The blue column should touch the trailing edge.",
                component: horizontalNestedFlexStack,
                localizedStrings: [
                    "horizontal_inner_leading": .string("L"),
                    "horizontal_inner_trailing": .string("T"),
                    "horizontal_outer_trailing": .string("End")
                ]
            )
            .previewLayout(.fixed(width: 390, height: 210))
            .previewDisplayName("Nested Flex · Horizontal")
        }
    }

}

private let nestedFlexStackPreviewBackground = Color(
    red: 226.0 / 255.0,
    green: 232.0 / 255.0,
    blue: 240.0 / 255.0
)

private let verticalNestedFlexStack = PaywallComponent.StackComponent(
    components: [
        .stack(.init(
            components: [
                nestedFlexPreviewText(
                    "vertical_inner_top",
                    size: .init(width: .fill, height: .fixed(32)),
                    backgroundColor: "#DC2626"
                ),
                nestedFlexPreviewText(
                    "vertical_inner_bottom",
                    size: .init(width: .fill, height: .fixed(32)),
                    backgroundColor: "#16A34A"
                )
            ],
            dimension: .vertical(.center, .spaceBetween),
            size: .init(
                width: .fill,
                height: .fit(nil, .init(min: 120, max: nil))
            ),
            spacing: 0,
            backgroundColor: .init(light: .hex("#CBD5E1")),
            padding: .zero
        )),
        nestedFlexPreviewText(
            "vertical_outer_bottom",
            size: .init(width: .fill, height: .fixed(32)),
            backgroundColor: "#2563EB"
        )
    ],
    dimension: .vertical(.center, .spaceBetween),
    size: .init(
        width: .fixed(240),
        height: .fit(nil, .init(min: 280, max: nil))
    ),
    spacing: 0,
    backgroundColor: .init(light: .hex("#FFFFFF")),
    padding: .zero
)

private let horizontalNestedFlexStack = PaywallComponent.StackComponent(
    components: [
        .stack(.init(
            components: [
                nestedFlexPreviewText(
                    "horizontal_inner_leading",
                    size: .init(width: .fixed(40), height: .fill),
                    backgroundColor: "#DC2626"
                ),
                nestedFlexPreviewText(
                    "horizontal_inner_trailing",
                    size: .init(width: .fixed(40), height: .fill),
                    backgroundColor: "#16A34A"
                )
            ],
            dimension: .horizontal(.center, .spaceBetween),
            size: .init(
                width: .fit(nil, .init(min: 140, max: nil)),
                height: .fill
            ),
            spacing: 0,
            backgroundColor: .init(light: .hex("#CBD5E1")),
            padding: .zero
        )),
        nestedFlexPreviewText(
            "horizontal_outer_trailing",
            size: .init(width: .fixed(40), height: .fill),
            backgroundColor: "#2563EB"
        )
    ],
    dimension: .horizontal(.center, .spaceBetween),
    size: .init(
        width: .fit(nil, .init(min: 320, max: nil)),
        height: .fixed(72)
    ),
    spacing: 0,
    backgroundColor: .init(light: .hex("#FFFFFF")),
    padding: .zero
)

private func nestedFlexPreviewText(
    _ text: String,
    size: PaywallComponent.Size,
    backgroundColor: String
) -> PaywallComponent {
    return .text(.init(
        text: text,
        color: .init(light: .hex("#FFFFFF")),
        backgroundColor: .init(light: .hex(backgroundColor)),
        size: size
    ))
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private func nestedFlexStackPreview(
    title: String,
    detail: String,
    component: PaywallComponent.StackComponent,
    localizedStrings: PaywallComponent.LocalizationDictionary
) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
        StackComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                component: component,
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: localizedStrings
                ),
                colorScheme: .light
            ),
            onDismiss: {}
        )
        .overlay {
            Rectangle()
                .stroke(Color.pink, lineWidth: 1)
        }
        .previewRequiredPaywallsV2Properties()

        Text(detail)
            .font(.caption)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(nestedFlexStackPreviewBackground)
}

#endif
