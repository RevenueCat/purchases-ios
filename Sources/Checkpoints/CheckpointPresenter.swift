//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointPresenter.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// Presents checkpoint experiences.
///
/// This is implemented by RevenueCatUI so the core module can request presentation without depending on UI code.
@MainActor
@_spi(Internal) public protocol CheckpointPresenter: AnyObject {

    /// Presents an experience for a checkpoint.
    ///
    /// Implementations must report exactly one terminal result through `delegate`.
    func present(
        callID: String,
        presentation: CheckpointWorkflowPresentation,
        delegate: CheckpointPresenterDelegate
    )

}

/// Creates the RevenueCatUI checkpoint presenter when that module is linked into the application.
@MainActor
@_spi(Internal) public protocol CheckpointPresenterProvider: AnyObject {

    /// Creates a presenter supplied by RevenueCatUI.
    static func makeCheckpointPresenter() -> CheckpointPresenter

}

/// Receives terminal results from a checkpoint presenter.
@_spi(Internal) public protocol CheckpointPresenterDelegate: AnyObject {

    /// Reports that the presented experience finished.
    func onCheckpointPaywallFinished(callID: String, outcome: CheckpointPaywallOutcome)

}
