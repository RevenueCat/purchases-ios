//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointPresenterProvider.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) import RevenueCat

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

import Foundation

/// Runtime-discoverable bridge that lets RevenueCat request UI without depending on RevenueCatUI.
@objc(RCCheckpointPresenterProvider)
@MainActor
final class RevenueCatUICheckpointPresenterProvider: NSObject, CheckpointPresenterProvider {

    static func makeCheckpointPresenter() -> CheckpointPresenter {
        if #available(iOS 15.0, macOS 12.0, *) {
            return CheckpointWorkflowPresenter()
        } else {
            return UnsupportedCheckpointPresenter()
        }
    }

}

@MainActor
private final class UnsupportedCheckpointPresenter: CheckpointPresenter {

    func present(
        callID: String,
        presentation: CheckpointWorkflowPresentation,
        delegate: CheckpointPresenterDelegate
    ) {
        delegate.onCheckpointPaywallFinished(
            callID: callID,
            outcome: CheckpointPaywallErrorOutcome(
                error: NSError(
                    domain: "RevenueCatUI.CheckpointWorkflow",
                    code: 2,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Checkpoint presentation requires iOS 15 or newer."
                    ]
                )
            )
        )
    }

}

#endif
