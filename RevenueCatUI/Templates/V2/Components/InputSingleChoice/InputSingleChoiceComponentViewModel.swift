//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InputSingleChoiceComponentViewModel.swift
//
//  Created by AI Assistant
//

import Foundation
@_spi(Internal) import RevenueCat
#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class InputSingleChoiceComponentViewModel {

    let component: PaywallComponent.InputSingleChoiceComponent
    let stackViewModel: StackComponentViewModel

    init(
        component: PaywallComponent.InputSingleChoiceComponent,
        stackViewModel: StackComponentViewModel
    ) {
        self.component = component
        self.stackViewModel = stackViewModel
    }

    /// Returns the onPressActionId from the first InputOption component found in the stack
    /// This assumes that when InputSingleChoice is clicked, it should trigger the workflow
    /// action from the selected/active option. For now, we'll use the first option found.
    var onPressActionId: String? {
        return findFirstInputOptionActionId(in: self.stackViewModel.viewModels)
    }

    private func findFirstInputOptionActionId(in viewModels: [PaywallComponentViewModel]) -> String? {
        for viewModel in viewModels {
            switch viewModel {
            case .inputOption(let optionViewModel):
                return optionViewModel.onPressActionId
            case .stack(let stackViewModel):
                if let actionId = findFirstInputOptionActionId(in: stackViewModel.viewModels) {
                    return actionId
                }
            default:
                continue
            }
        }
        return nil
    }

}

#endif
