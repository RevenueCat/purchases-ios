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

/// Explains whether a configured help path appears for a simulated purchase.
@available(iOS 15.0, *)
@_spi(Internal) public struct CustomerCenterPreviewDiagnostic: Sendable, Equatable {
    /// Identifier of the configured help path.
    public let pathID: String
    /// Display title of the help path.
    public let title: String
    /// Identifier of the purchase being evaluated, if any.
    public let productID: String?
    /// Whether the rendering rules include the path.
    public let visible: Bool
    /// Human-readable explanation of visibility.
    public let reason: String

    /// Creates a diagnostic from the same eligibility rules used by the view.
    public init(pathID: String, title: String, productID: String?, visible: Bool, reason: String) {
        self.pathID = pathID
        self.title = title
        self.productID = productID
        self.visible = visible
        self.reason = reason
    }
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
    /// Receives path visibility diagnostics.
    func onPreviewDiagnostics(_ diagnostics: [CustomerCenterPreviewDiagnostic])
}

@available(iOS 15.0, *)
extension CustomerCenterPreviewProvider {
    /// Defaults to the standalone offering when the provider has no workflow support.
    public func previewWorkflow(for offering: Offering) async throws -> WorkflowContext? { nil }
    /// Defaults to ineligible promotional offers.
    public func previewPromotionalOfferEligibility() async -> Bool { false }
    /// Defaults to no preview variable overrides.
    public func previewCustomVariables() async -> [String: CustomVariableValue] { [:] }
    /// Ignores diagnostics when the provider has no diagnostics interface.
    public func onPreviewDiagnostics(_ diagnostics: [CustomerCenterPreviewDiagnostic]) {}
}

/// Intercepts links throughout Customer Center only for injected preview providers.
@available(iOS 15.0, *)
struct CustomerCenterPreviewURLModifier: ViewModifier {
    let provider: CustomerCenterPurchasesType

    @ViewBuilder func body(content: Content) -> some View {
        if let preview = provider as? CustomerCenterPreviewProvider {
            content.environment(\.openURL, OpenURLAction { url in
                Task { try? await preview.handlePreviewAction(.openURL(url)) }
                return .handled
            })
        } else {
            content
        }
    }
}

/// Intercepts platform sheets only when a preview provider is present.
@available(iOS 15.0, *)
struct CustomerCenterPreviewActionModifier: ViewModifier {
    let provider: CustomerCenterPreviewProvider
    @Binding var isPresented: Bool
    let action: CustomerCenterPreviewAction
    @State private var failure: String?

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ProgressView().padding().background(.regularMaterial).cornerRadius(12)
                }
            }
            .task(id: isPresented) {
                guard isPresented else { return }
                do {
                    try await provider.handlePreviewAction(action)
                    try Task.checkCancellation()
                    isPresented = false
                } catch is CancellationError {
                    // A provider may cancel an action without cancelling the view task.
                    if !Task.isCancelled { isPresented = false }
                } catch {
                    guard !Task.isCancelled else { return }
                    let nsError = error as NSError
                    if nsError.domain != ErrorCode.errorDomain
                        || nsError.code != ErrorCode.purchaseCancelledError.rawValue {
                        failure = error.localizedDescription
                    }
                    isPresented = false
                }
            }
            .alert("Preview action failed", isPresented: Binding(
                get: { failure != nil }, set: { if !$0 { failure = nil } }
            )) {
                Button("OK", role: .cancel) { failure = nil }
            } message: {
                Text(failure ?? "")
            }
    }
}

@available(iOS 15.0, *)
extension CustomerCenterViewModel {
    func observePreviewUpdates() async {
        guard let provider = purchasesProvider as? CustomerCenterPreviewProvider else { return }
        let updates = await provider.customerInfoUpdates()
        for await _ in updates {
            guard !Task.isCancelled else { break }
            manageSubscriptionsSheet = false
            changePlansSheet = false
            await loadScreen()
        }
    }
}
#endif
