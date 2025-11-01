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

}

#endif
