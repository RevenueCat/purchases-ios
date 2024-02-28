//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Package.swift
//
//  Created by Andrés Boedo on 6/18/21.
//

import Foundation

///
/// Stores information about how a ``Package`` was presented.
///
@objc(RCPresentedOfferingContext) public final class PresentedOfferingContext: NSObject {

    ///
    /// Stores information a targeting rule
    ///
    @objc(RCTargetingContext) public final class TargetingContext: NSObject {
        /// The revision of the targeting used to obtain this object.
        @objc public let revision: Int

        /// The rule id from the targeting used to obtain this object.
        @objc public let ruleId: String

        /// Initializes a ``TargetingContext``
        @objc
        public init(revision: Int, ruleId: String) {
            self.revision = revision
            self.ruleId = ruleId
        }
    }

    /// The identifier of the ``Offering`` containing this ``Package``.
    @objc public let offeringIdentifier: String

    /// The placement identifier this ``Package`` was obtained from.
    @objc public let placementIdentifier: String?

    /// The targeting rule this ``Package`` was obtained from.
    @objc public let targetingContext: TargetingContext?

    /// Initialize a ``PresentedOfferingContext``.
    @objc
    public init(
        offeringIdentifier: String,
        placementIdentifier: String?,
        targetingContext: TargetingContext?
    ) {
        self.offeringIdentifier = offeringIdentifier
        self.placementIdentifier = placementIdentifier
        self.targetingContext = targetingContext
        super.init()
    }

    /// Initialize a ``PresentedOfferingContext``.
    @objc
    public convenience init(
        offeringIdentifier: String
    ) {
        self.init(offeringIdentifier: offeringIdentifier, placementIdentifier: nil, targetingContext: nil)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PresentedOfferingContext else { return false }

        return (
            self.offeringIdentifier == other.offeringIdentifier
        )
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.offeringIdentifier)

        return hasher.finalize()
    }
}

///
/// Packages help abstract platform-specific products by grouping equivalent products across iOS, Android, and web.
/// A package is made up of three parts: ``identifier``, ``packageType``, and underlying ``StoreProduct``.
///
/// #### Related Articles
/// - [Displaying Packages](https://docs.revenuecat.com/docs/displaying-products#displaying-packages)
/// - ``Offering``
/// - ``Offerings``
///
@objc(RCPackage) public final class Package: NSObject {

    /// The identifier for this Package.
    @objc public let identifier: String
    /// The type configured for this package.
    @objc public let packageType: PackageType
    /// The underlying ``storeProduct``
    @objc public let storeProduct: StoreProduct

    ////  The information about the ``Offering`` containing this Package
    @objc public let presentedOfferingContext: PresentedOfferingContext

    /// The price of this product using ``StoreProduct/priceFormatter``.
    @objc public var localizedPriceString: String {
        return storeProduct.localizedPriceString
    }

    /// The price of the ``StoreProduct/introductoryDiscount`` formatted using ``StoreProduct/priceFormatter``.
    /// - Returns: `nil` if there is no `introductoryDiscount`.
    @objc public var localizedIntroductoryPriceString: String? {
        return self.storeProduct.localizedIntroductoryPriceString
    }

    /// Initialize a ``Package``.
    @objc
    public convenience init(
        identifier: String,
        packageType: PackageType,
        storeProduct: StoreProduct,
        offeringIdentifier: String
    ) {
        self.init(
            identifier: identifier,
            packageType: packageType,
            storeProduct: storeProduct,
            presentedOfferingContext: .init(offeringIdentifier: offeringIdentifier)
        )
    }

    /// Initialize a ``Package``.
    @objc
    public init(
        identifier: String,
        packageType: PackageType,
        storeProduct: StoreProduct,
        presentedOfferingContext: PresentedOfferingContext
    ) {
        self.identifier = identifier
        self.packageType = packageType
        self.storeProduct = storeProduct
        self.presentedOfferingContext = presentedOfferingContext

        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Package else { return false }

        return (
            self.identifier == other.identifier &&
            self.packageType == other.packageType &&
            self.storeProduct == other.storeProduct &&
            self.presentedOfferingContext == other.presentedOfferingContext
        )
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.identifier)
        hasher.combine(self.packageType)
        hasher.combine(self.storeProduct)
        hasher.combine(self.presentedOfferingContext)

        return hasher.finalize()
    }

}

@objc public extension Package {

    /**
     * - Parameter packageType: A ``PackageType``.
     * - Returns: an optional description of the packageType.
     */
    static func string(from packageType: PackageType) -> String? {
        return packageType.description
    }

    /**
     * - Parameter string: A string that maps to a enumeration value of type ``PackageType``
     * - Returns: a ``PackageType`` for the given string.
     */
    static func packageType(from string: String) -> PackageType {
        if let packageType = PackageType.typesByDescription[string] {
            return packageType
        }

        return string.hasPrefix("$rc_") ? .unknown : .custom
    }

    /// - Returns: the identifier of the ``Offering`` containing this Package.
    var offeringIdentifier: String {
        return self.presentedOfferingContext.offeringIdentifier
    }
}

extension Package: Identifiable {

    /// The stable identity of the entity associated with this instance.
    public var id: String { return self.identifier }

}

extension Package: Sendable {}
extension PresentedOfferingContext: Sendable {}
extension PresentedOfferingContext.TargetingContext: Sendable {}
