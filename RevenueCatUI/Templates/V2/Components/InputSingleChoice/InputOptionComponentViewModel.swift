//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InputOptionComponentViewModel.swift

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class InputOptionComponentViewModel {

    let component: PaywallComponent.InputOptionComponent
    let stackViewModel: StackComponentViewModel

    init(
        component: PaywallComponent.InputOptionComponent,
        stackViewModel: StackComponentViewModel
    ) {
        self.component = component
        self.stackViewModel = stackViewModel
    }

}

#endif
