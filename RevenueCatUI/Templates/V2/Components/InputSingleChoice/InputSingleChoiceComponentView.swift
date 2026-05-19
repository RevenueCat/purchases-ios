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
private struct InputSingleChoicePreviewHelper: View {

    let innerStackViewModel: StackComponentViewModel
    let preselectedOptionId: String?

    @StateObject private var context: InputSingleChoiceContext

    init(innerStackViewModel: StackComponentViewModel, preselectedOptionId: String? = nil) {
        self.innerStackViewModel = innerStackViewModel
        self.preselectedOptionId = preselectedOptionId
        let ctx = InputSingleChoiceContext(fieldId: "plan_type")
        ctx.selectedOptionId = preselectedOptionId
        self._context = StateObject(wrappedValue: ctx)
    }

    var body: some View {
        StackComponentView(viewModel: innerStackViewModel, onDismiss: {})
            .environmentObject(context)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct InputSingleChoiceComponentView_Previews: PreviewProvider {

    static func optionStack(labelKey: String) -> PaywallComponent.StackComponent {
        .init(
            components: [
                .text(.init(
                    text: labelKey,
                    color: .init(light: .hex("#1c1c1e")),
                    size: .init(width: .fit, height: .fit),
                    overrides: [
                        .init(conditions: [.selected], properties: .init(
                            color: .init(light: .hex("#ffffff"))
                        ))
                    ]
                ))
            ],
            dimension: .horizontal(.center, .center),
            size: .init(width: .fill, height: .fixed(52)),
            padding: .init(top: 0, bottom: 0, leading: 16, trailing: 16),
            shape: .rectangle(.init(topLeading: 10, topTrailing: 10, bottomLeading: 10, bottomTrailing: 10)),
            border: .init(color: .init(light: .hex("#3d6787")), width: 1.5),
            overrides: [
                .init(conditions: [.selected], properties: .init(
                    backgroundColor: .init(light: .hex("#3d6787"))
                ))
            ]
        )
    }

    static let innerStack = PaywallComponent.StackComponent(
        components: [
            .inputOption(.init(
                optionId: "monthly", optionValue: "monthly", stack: optionStack(labelKey: "monthly_label")
            )),
            .inputOption(.init(
                optionId: "annual", optionValue: "annual", stack: optionStack(labelKey: "annual_label")
            )),
            .inputOption(.init(
                optionId: "lifetime", optionValue: "lifetime", stack: optionStack(labelKey: "lifetime_label")
            ))
        ],
        dimension: .vertical(.leading, .start),
        size: .init(width: .fill, height: .fit),
        spacing: 12
    )

    static let localization: LocalizationProvider = .init(
        locale: Locale.current,
        localizedStrings: [
            "monthly_label": .string("Monthly · $4.99 / mo"),
            "annual_label": .string("Annual · $39.99 / yr"),
            "lifetime_label": .string("Lifetime · $99.99")
        ]
    )

    // swiftlint:disable:next force_try
    static let innerVM = try! StackComponentViewModel(
        component: innerStack,
        localizationProvider: localization,
        colorScheme: .light
    )

    static let wrapperComponent = PaywallComponent.StackComponent(
        components: [],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fill),
        backgroundColor: .init(light: .hex("#f2f2f7")),
        padding: .init(top: 24, bottom: 24, leading: 16, trailing: 16)
    )

    static var previews: some View {
        // None selected
        InputSingleChoicePreviewHelper(innerStackViewModel: innerVM)
            .padding(24)
            .background(Color(red: 0.95, green: 0.95, blue: 0.97))
            .previewRequiredPaywallsV2Properties()
            .previewLayout(.fixed(width: 390, height: 240))
            .previewDisplayName("None selected")

        // Annual pre-selected
        InputSingleChoicePreviewHelper(innerStackViewModel: innerVM, preselectedOptionId: "annual")
            .padding(24)
            .background(Color(red: 0.95, green: 0.95, blue: 0.97))
            .previewRequiredPaywallsV2Properties()
            .previewLayout(.fixed(width: 390, height: 240))
            .previewDisplayName("Annual selected")
    }

}

#endif

#endif
