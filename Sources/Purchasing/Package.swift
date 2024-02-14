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
@objc(RCPresentedOfferingData) public final class PresentedOfferingData: NSObject {

    /// The identifier of the ``Offering`` containing this Package.
    @objc public let offeringIdentifier: String

    /// Initialize a ``PresentedOfferingData``.
    @objc
    public init(
        offeringIdentifier: String
    ) {
        self.offeringIdentifier = offeringIdentifier
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PresentedOfferingData else { return false }

        return (
            self.offeringIdentifier == other.offeringIdentifier
        )
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
    @objc public let presentedOfferingData: PresentedOfferingData

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
    public init(
        identifier: String,
        packageType: PackageType,
        storeProduct: StoreProduct,
        offeringIdentifier: String
    ) {
        self.identifier = identifier
        self.packageType = packageType
        self.storeProduct = storeProduct
        self.presentedOfferingData = PresentedOfferingData(offeringIdentifier: offeringIdentifier)

        super.init()
    }

    /// Initialize a ``Package``.
    @objc
    public init(
        identifier: String,
        packageType: PackageType,
        storeProduct: StoreProduct,
        presentedOfferingData: PresentedOfferingData
    ) {
        self.identifier = identifier
        self.packageType = packageType
        self.storeProduct = storeProduct
        self.presentedOfferingData = presentedOfferingData

        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Package else { return false }

        return (
            self.identifier == other.identifier &&
            self.packageType == other.packageType &&
            self.storeProduct == other.storeProduct &&
            self.presentedOfferingData == other.presentedOfferingData
        )
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.identifier)
        hasher.combine(self.packageType)
        hasher.combine(self.storeProduct)
        hasher.combine(self.presentedOfferingData.offeringIdentifier)

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
        return presentedOfferingData.offeringIdentifier
    }
}

extension Package: Identifiable {

    /// The stable identity of the entity associated with this instance.
    public var id: String { return self.identifier }

}

extension Package: Sendable {}
extension PresentedOfferingData: Sendable {}
