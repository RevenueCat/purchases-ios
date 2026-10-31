//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) @testable import RevenueCatUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CheckpointCallParams {

    convenience init(
        customVariables: [String: CustomVariableValue] = [:],
        presentationMode: FlowPresentationMode = .default,
        paywallPresenter: PaywallPresentationHandler? = nil,
        errorPresenter: ErrorPresentationHandler? = nil
    ) {
        self.init(
            customVariables: customVariables,
            presentationMode: presentationMode,
            paywallPresenter: paywallPresenter,
            errorPresenter: errorPresenter,
            errorDialogFactory: nil
        )
    }

}
