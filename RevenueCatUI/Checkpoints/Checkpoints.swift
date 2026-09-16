//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Checkpoints.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CustomVariableValue {

    var coreCheckpointValue: RevenueCat.CheckpointValue {
        return self.map(
            string: { .string($0) },
            number: { .double($0) },
            boolean: { .boolean($0) }
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointCallParams: @unchecked Sendable {

    let customVariables: [String: CustomVariableValue]
    let localPaywallPresentationHandler: PaywallPresentationHandler?

    init(
        customVariables: [String: CustomVariableValue] = [:],
        paywallPresenter: PaywallPresentationHandler? = nil
    ) {
        self.customVariables = RevenueCat.CustomVariableKeyValidator.validateAndFilter(customVariables)
        self.localPaywallPresentationHandler = paywallPresenter
    }

    var coreParams: RevenueCat.CheckpointParams {
        return .init(customVariables: self.customVariables.mapValues(\.coreCheckpointValue))
    }

}
