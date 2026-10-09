//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPreviewProvider.swift
//
//  Created by Monika on 6/10/2026.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

/// Platform actions delegated to an isolated preview session.
@available(iOS 15.0, *)
@_spi(Internal) public enum CustomerCenterPreviewAction: Sendable {
    /// Simulates cancellation or resubscription.
    case manageSubscriptions
    /// Presents alternatives for the currently selected subscription.
    case changePlans(currentProductID: String?, productIDs: [String], subscriptionGroupID: String?)
    /// Describes a link without opening it.
    case openURL(URL)
    /// Describes the configured custom action.
    case customAction(String)
}

/// Internal hooks for isolated, stateful previews. Normal SDK integrations do not use this provider.
@available(iOS 15.0, *)
@_spi(Internal) public protocol CustomerCenterPreviewProvider: CustomerCenterPurchasesType {
    /// Emits customer changes for the lifetime of this preview.
    func customerInfoUpdates() async -> AsyncStream<CustomerInfo>
    /// Handles platform actions without interacting with StoreKit or external applications.
    func handlePreviewAction(_ action: CustomerCenterPreviewAction) async throws
    /// Resolves an optional workflow using app-supplied data.
    func previewWorkflow(for offering: Offering) async throws -> WorkflowContext?
    /// Indicates whether paywall promotional offers should be simulated as eligible.
    func previewPromotionalOfferEligibility() async -> Bool
    /// Supplies the project variables entered in the mobile preview settings.
    func previewCustomVariables() async -> [String: CustomVariableValue]
}

@available(iOS 15.0, *)
extension CustomerCenterPreviewProvider {
    /// Defaults to the standalone offering when the provider has no workflow support.
    public func previewWorkflow(for offering: Offering) async throws -> WorkflowContext? { nil }
    /// Defaults to ineligible promotional offers.
    public func previewPromotionalOfferEligibility() async -> Bool { false }
    /// Defaults to no preview variable overrides.
    public func previewCustomVariables() async -> [String: CustomVariableValue] { [:] }
}
#endif
