//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InputOptionComponentView.swift

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct InputOptionComponentView: View {

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var packageContext: PackageContext

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    @Environment(\.workflowTriggerAction)
    private var workflowTriggerAction

    @EnvironmentObject
    private var inputSingleChoiceContext: InputSingleChoiceContext

    private let viewModel: InputOptionComponentViewModel
    private let onDismiss: () -> Void

    init(viewModel: InputOptionComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    private var selectedState: ComponentViewState {
        inputSingleChoiceContext.selectedOptionId == viewModel.component.optionId ? .selected : .default
    }

    var body: some View {
        Button {
            inputSingleChoiceContext.selectedOptionId = viewModel.component.optionId
            if let triggerAction = workflowTriggerAction {
                _ = triggerAction(viewModel.component.optionId)
            }
        } label: {
            StackComponentView(
                viewModel: viewModel.stackViewModel,
                onDismiss: onDismiss
            )
            .environment(\.componentViewState, selectedState)
        }
    }

}

#endif
