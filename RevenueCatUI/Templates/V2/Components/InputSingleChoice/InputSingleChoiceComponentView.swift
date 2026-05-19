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

#endif
