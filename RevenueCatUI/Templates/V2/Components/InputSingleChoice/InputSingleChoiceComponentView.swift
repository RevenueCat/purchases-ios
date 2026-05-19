//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InputSingleChoiceComponentView.swift

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct InputSingleChoiceComponentView: View {

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var packageContext: PackageContext

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    @StateObject
    private var inputContext: InputSingleChoiceContext

    private let viewModel: InputSingleChoiceComponentViewModel
    private let onDismiss: () -> Void

    init(viewModel: InputSingleChoiceComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self._inputContext = StateObject(
            wrappedValue: InputSingleChoiceContext(fieldId: viewModel.component.fieldId)
        )
    }

    var body: some View {
        StackComponentView(
            viewModel: viewModel.stackViewModel,
            onDismiss: onDismiss
        )
        .environmentObject(inputContext)
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct InputSingleChoiceComponentView_Previews: PreviewProvider {

    static let optionStack = PaywallComponent.StackComponent(
        components: [
            .text(.init(
                text: "option_label",
                color: .init(light: .hex("#000000")),
                size: .init(width: .fit, height: .fit),
                overrides: [
                    .init(conditions: [.selected], properties: .init(
                        color: .init(light: .hex("#ffffff"))
                    ))
                ]
            ))
        ],
        dimension: .horizontal(.center, .center),
        size: .init(width: .fill, height: .fixed(48)),
        padding: .init(top: 0, bottom: 0, leading: 16, trailing: 16),
        shape: .rectangle(.init(topLeading: 8, topTrailing: 8, bottomLeading: 8, bottomTrailing: 8)),
        border: .init(color: .init(light: .hex("#3d6787")), width: 1),
        overrides: [
            .init(conditions: [.selected], properties: .init(
                backgroundColor: .init(light: .hex("#3d6787"))
            ))
        ]
    )

    static let inputSingleChoice = PaywallComponent.inputSingleChoice(
        .init(
            fieldId: "plan_type",
            stack: .init(
                components: [
                    .inputOption(.init(
                        optionId: "monthly",
                        optionValue: "monthly",
                        stack: optionStack
                    )),
                    .inputOption(.init(
                        optionId: "annual",
                        optionValue: "annual",
                        stack: optionStack
                    )),
                    .inputOption(.init(
                        optionId: "lifetime",
                        optionValue: "lifetime",
                        stack: optionStack
                    ))
                ],
                dimension: .vertical(.leading, .start),
                size: .init(width: .fill, height: .fit),
                spacing: 12
            )
        )
    )

    static var previews: some View {
        StackComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! StackComponentViewModel(
                component: .init(
                    components: [inputSingleChoice],
                    dimension: .vertical(.center, .start),
                    size: .init(width: .fill, height: .fill),
                    backgroundColor: .init(light: .hex("#f5f5f5")),
                    padding: .init(top: 24, bottom: 24, leading: 16, trailing: 16)
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "option_label": .string("Option")
                    ]
                ),
                colorScheme: .light
            ),
            onDismiss: {}
        )
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: 390, height: 300))
        .previewDisplayName("InputSingleChoice - 3 options")
    }

}

#endif

#endif
