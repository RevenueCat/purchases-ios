//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointPaywallPresenter.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// Presents a paywall offering selected by a checkpoint using app-owned UI.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public protocol CheckpointPaywallPresenter: AnyObject {

    /// Presents `offering` and reports the terminal result through `completion`.
    ///
    /// The checkpoint remains pending until the completion is reported. Only the first completion method call
    /// is used; later calls are ignored.
    func present(
        offering: Offering,
        completion: CheckpointPaywallCompletion
    ) throws

}
/// Reports how an app-owned checkpoint paywall presentation finished.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public protocol CheckpointPaywallCompletion: AnyObject {

    /// The app-owned paywall presentation finished.
    ///
    /// RevenueCat fetches the latest customer information after this call to determine any entitlement grants.
    func finished()

    /// The app-owned paywall presentation failed before it finished.
    func failed()

}
