//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointsManager+Embedded.swift
//
//  Created by Cesar de la Vega.
//

import Foundation
@_spi(Internal) import RevenueCat

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import UIKit

@available(iOS 15.0, macOS 12.0, *)
extension CheckpointsManager {

    /// Runs a checkpoint whose flow is embedded in `parentViewController` by the SDK. Lifecycle callbacks are
    /// explicit so hybrid callers can render their own UI (for example, error dialogs) above the native child.
    // swiftlint:disable:next function_parameter_count
    func checkpointEmbedded(
        _ identifier: String,
        customVariables: [String: CustomVariableValue],
        parentViewController: UIViewController,
        errorPresenter: @escaping ErrorPresentationHandler,
        onPassed: @escaping (CheckpointResult) -> Void,
        onFinished: @escaping () -> Void
    ) -> EmbeddedCheckpointExecution {
        let execution = EmbeddedCheckpointExecution(parentViewController: parentViewController,
                                                    onFinished: onFinished)
        // The child fills the parent, so the parent decides sheet versus full screen; the mode only has to
        // be a resolved value for the presenters.
        let params = CheckpointCallParams(customVariables: customVariables, presentationMode: .modalFullScreen,
                                          errorPresenter: errorPresenter, execution: execution)
        execution.task = Task { @MainActor in
            defer { execution.finish() }
            guard !execution.isCancelled else { return }
            guard EmbeddedCheckpointPresentation.isUsableParent(execution.parentViewController) else {
                await self.presentCheckpointError(
                    CheckpointError.presentationFailed,
                    identifier: identifier,
                    params: params,
                    kind: .flowCouldNotBeShown
                )
                return
            }
            let result = await self.checkpointForCallback(identifier: identifier, params: params)
            guard !execution.isCancelled else { return }
            if case let .completed(result) = result { onPassed(result) }
        }
        return execution
    }

}
#endif
