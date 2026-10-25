//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointResults.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// The result of completing a checkpoint flow.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct FlowResult: Sendable {

    /// Active entitlements present after the flow that were not active before it was presented.
    ///
    /// The SDK compares the customer information delivered with the result against the one read before presenting
    /// the flow.
    public let obtainedEntitlements: Set<ObtainedEntitlement>

    /// Products newly observed after the flow completed, among those its offerings sell.
    ///
    /// The SDK compares the purchase dates in the customer information delivered with the result against the ones
    /// read before presenting the flow: a renewal or a repeat purchase counts.
    public let obtainedProducts: Set<ObtainedProduct>

    init(
        obtainedEntitlements: Set<ObtainedEntitlement>,
        obtainedProducts: Set<ObtainedProduct>
    ) {
        self.obtainedEntitlements = obtainedEntitlements
        self.obtainedProducts = obtainedProducts
    }

    /// Returns the entitlement with `identifier` that was obtained while the flow was presented.
    public func obtainedEntitlement(_ identifier: String) -> ObtainedEntitlement? {
        return self.obtainedEntitlements.first { $0.entitlementInfo.identifier == identifier }
    }

    /// Returns whether the entitlement with `identifier` was obtained while the flow was presented.
    public func didObtainEntitlement(_ identifier: String) -> Bool {
        return self.obtainedEntitlement(identifier) != nil
    }

    /// Returns the product with `identifier` that was newly observed after the flow completed.
    ///
    /// `identifier` is the product's store identifier. When more than one billing plan of a product was obtained,
    /// the plain identifier returns the up-front plan; suffix it with `:` and the billing plan type
    /// (`"com.app.annual:monthly"`) to select another.
    public func obtainedProduct(_ identifier: String) -> ObtainedProduct? {
        return self.obtainedProducts.first { $0.product.id == identifier }
            ?? self.obtainedProducts.first { $0.product.productIdentifier == identifier }
    }

    /// Returns whether the product with `identifier` was newly observed after the flow completed. See
    /// ``obtainedProduct(_:)`` for the identifier's format.
    public func didObtainProduct(_ identifier: String) -> Bool {
        return self.obtainedProduct(identifier) != nil
    }

}

/// An active entitlement reported after completing a checkpoint flow.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct ObtainedEntitlement: Hashable, Sendable {

    /// Information about the active entitlement reported after the flow.
    public let entitlementInfo: EntitlementInfo

    init(entitlementInfo: EntitlementInfo) {
        self.entitlementInfo = entitlementInfo
    }

    /// Returns whether two obtained entitlements represent the same entitlement identifier.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.entitlementInfo.identifier == rhs.entitlementInfo.identifier
    }

    /// Hashes the entitlement identifier.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.entitlementInfo.identifier)
    }

}

/// A product newly observed after completing a checkpoint flow.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct ObtainedProduct: Hashable, Sendable {

    /// The product observed after completing the flow.
    public let product: StoreProduct

    init(product: StoreProduct) {
        self.product = product
    }

    /// Returns whether two obtained products represent the same product and billing plan.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.product.id == rhs.product.id
    }

    /// Hashes the product identifier and billing plan.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.product.id)
    }

}

extension CustomerInfo {

    var activeEntitlementIdentifiers: Set<String> {
        return Set(self.entitlements.active.keys)
    }

    func obtainedEntitlements(
        comparedTo initialActiveEntitlementIdentifiers: Set<String>?
    ) -> [EntitlementInfo] {
        guard let initialActiveEntitlementIdentifiers else {
            return Array(self.entitlements.active.values)
        }

        return self.entitlements.active.values.filter { entitlement in
            return !initialActiveEntitlementIdentifiers.contains(entitlement.identifier)
        }
    }

    func grantsNewEntitlements(
        comparedTo initialActiveEntitlementIdentifiers: Set<String>?
    ) -> Bool {
        return !self.obtainedEntitlements(comparedTo: initialActiveEntitlementIdentifiers).isEmpty
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func obtainedProducts(
        comparedTo initialCustomerInfo: CustomerInfo?,
        from availableProducts: [StoreProduct]
    ) -> [ObtainedProduct] {
        let productsByIdentifier = Dictionary(
            availableProducts.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return productsByIdentifier.values.compactMap { product in
            let identifier = product.id
            guard let purchaseDate = self.purchaseDate(forProductIdentifier: identifier),
                  purchaseDate != initialCustomerInfo?.purchaseDate(forProductIdentifier: identifier) else {
                return nil
            }

            return ObtainedProduct(product: product)
        }
    }

}

/// Base class for the terminal outcome of a checkpoint-presented ad.
///
/// Inspect the concrete outcome type to determine how the ad finished:
///
/// ```swift
/// switch adOutcome {
/// case is CheckpointAdOutcome.Shown:
///     handleShown()
/// case let outcome as CheckpointAdOutcome.Rewarded:
///     handleReward(outcome.reward, outcome.moreRewards)
/// case is CheckpointAdOutcome.RewardVerificationFailed:
///     handleUnverifiedReward()
/// case let outcome as CheckpointAdOutcome.Failed:
///     handleError(outcome.error)
/// default:
///     // Handle outcome types added in future SDK versions.
///     break
/// }
/// ```
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class CheckpointAdOutcome: CustomStringConvertible, @unchecked Sendable {

    fileprivate init() {}

    /// A debug description of the ad outcome.
    public var description: String { return "CheckpointAdOutcome" }

    /// The ad was shown and dismissed, with no reward earned.
    public final class Shown: CheckpointAdOutcome, @unchecked Sendable {

        static let shared = Shown()

        private override init() { super.init() }

        public override var description: String { return "Shown" }

    }

    /// The customer earned the ad's reward and RevenueCat verified it. Any configured virtual currency or
    /// entitlement has already been granted by the time this outcome is reported.
    public final class Rewarded: CheckpointAdOutcome, @unchecked Sendable {

        /// The primary verified reward. Can be ``AdReward/noReward`` when verification succeeded but the
        /// ad unit has no reward configured.
        public let reward: AdReward

        /// Additional verified rewards, not repeating ``reward``.
        public let moreRewards: [AdReward]

        init(reward: AdReward, moreRewards: [AdReward]) {
            self.reward = reward
            self.moreRewards = moreRewards
            super.init()
        }

        public override var description: String {
            return "Rewarded(reward=\(self.reward), moreRewards=\(self.moreRewards))"
        }

    }

    /// The customer earned the ad's reward, but RevenueCat could not verify it, so nothing was granted.
    ///
    /// Unlike ``Failed``, the ad was shown in full; presenting another ad is not an appropriate recovery.
    public final class RewardVerificationFailed: CheckpointAdOutcome, @unchecked Sendable {

        static let shared = RewardVerificationFailed()

        private override init() { super.init() }

        public override var description: String { return "RewardVerificationFailed" }

    }

    /// The ad could not be shown, for example because it failed to load or the mediator had no fill.
    public final class Failed: CheckpointAdOutcome, @unchecked Sendable {

        /// The error that prevented the ad from being shown.
        public let error: PublicError

        init(error: PublicError) {
            self.error = error
            super.init()
        }

        public override var description: String { return "Failed(error=\(self.error))" }

    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CheckpointAdOutcome: Equatable {

    /// Returns whether two ad outcomes are the same case with equal associated values.
    public static func == (lhs: CheckpointAdOutcome, rhs: CheckpointAdOutcome) -> Bool {
        switch (lhs, rhs) {
        case (is Shown, is Shown):
            return true
        case let (lhs as Rewarded, rhs as Rewarded):
            return lhs.reward == rhs.reward && lhs.moreRewards == rhs.moreRewards
        case (is RewardVerificationFailed, is RewardVerificationFailed):
            return true
        case let (lhs as Failed, rhs as Failed):
            return lhs.error == rhs.error
        default:
            return false
        }
    }

}
