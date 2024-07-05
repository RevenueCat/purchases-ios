//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EntitlementInfos.swift
//
//  Created by Joshua Liebowitz on 6/28/21.
//

import Foundation

/**
 This class contains all the entitlements associated to the user.
 */
@objc(RCEntitlementInfos) public final class EntitlementInfos: NSObject {
    /**
     Dictionary of all EntitlementInfo (``EntitlementInfo``) objects (active and inactive) keyed by entitlement
     identifier. This dictionary can also be accessed by using an index subscript on ``EntitlementInfos``, e.g.
     `entitlementInfos["pro_entitlement_id"]`.
     */
    @objc public let all: [String: EntitlementInfo]

    /// #### Related Symbols
    /// - ``all``
    @objc public subscript(key: String) -> EntitlementInfo? {
        return self.all[key]
    }

    /// Whether these entitlements were verified.
    ///
    /// ### Related Articles
    /// - [Documentation](https://rev.cat/trusted-entitlements)
    ///
    /// ### Related Symbols
    /// - ``VerificationResult``
    @objc public var verification: VerificationResult { return self._verification }

    public override var description: String {
        return "<\(NSStringFromClass(Self.self)): " +
        "self.all=\(self.all), " +
        "self.active=\(self.active)," +
        "self.verification=\(self._verification)" +
        ">"
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? EntitlementInfos else {
            return false
        }

        return self.isEqual(to: other)
    }

    // MARK: -

    init(
        entitlements: [String: EntitlementInfo],
        verification: VerificationResult
    ) {
        self.all = entitlements
        self._verification = verification
    }

    private func isEqual(to other: EntitlementInfos?) -> Bool {
        guard let other = other else {
            return false
        }

        if self === other {
            return true
        }

        return self.all == other.all && self._verification == other._verification
    }

    private let _verification: VerificationResult

}

public extension EntitlementInfos {

    /// Dictionary of active ``EntitlementInfo`` objects keyed by their identifiers.
    /// - Warning: this is equivalent to ``activeInAnyEnvironment``
    ///
    /// #### Related Symbols
    /// - ``activeInCurrentEnvironment``
    @objc var active: [String: EntitlementInfo] {
        return self.activeInAnyEnvironment
    }

    /// Dictionary of active ``EntitlementInfo`` objects keyed by their identifiers.
    /// - Note: When queried from the sandbox environment, it only returns entitlements active in sandbox.
    /// When queried from production, this only returns entitlements active in production.
    ///
    /// #### Related Symbols
    /// - ``activeInAnyEnvironment``
    @objc var activeInCurrentEnvironment: [String: EntitlementInfo] {
        return self.all.filter { $0.value.isActiveInCurrentEnvironment }
    }

    /// Dictionary of active ``EntitlementInfo`` objects keyed by their identifiers.
    /// - Note: these can be active on any environment.
    ///
    /// #### Related Symbols
    /// - ``activeInCurrentEnvironment``
    @objc var activeInAnyEnvironment: [String: EntitlementInfo] {
        return self.all.filter { $0.value.isActiveInAnyEnvironment }
    }

}

extension EntitlementInfos {

    convenience init(
        entitlements: [String: CustomerInfoResponse.Entitlement],
        purchases: [String: CustomerInfoResponse.Subscription],
        requestDate: Date,
        sandboxEnvironmentDetector: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector.default,
        verification: VerificationResult
    ) {
        let allEntitlements: [String: EntitlementInfo] = .init(
            uniqueKeysWithValues: entitlements.compactMap { identifier, entitlement in
                guard let subscription = purchases[entitlement.productIdentifier] else {
                    return nil
                }

                return (
                    identifier,
                    EntitlementInfo(identifier: identifier,
                                    entitlement: entitlement,
                                    subscription: subscription,
                                    sandboxEnvironmentDetector: sandboxEnvironmentDetector,
                                    verification: verification,
                                    requestDate: requestDate)
                )
            }
        )

        self.init(entitlements: allEntitlements, verification: verification)
    }

}

extension EntitlementInfos: Sendable {}
