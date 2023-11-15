//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Storefront.swift
//
//  Created by Nacho Soto on 4/13/22.

import Foundation
import StoreKit

/// An object containing the location and unique identifier of an Apple App Store storefront.
///
/// - Note: Don't save the storefront information with your user information; storefront information can change
/// at any time. Always get the storefront identifier immediately before you display product information or availability
/// to the user in your app. Storefront information may not be used to develop or enhance a user profile,
/// or track customers for advertising or marketing purposes.
@objc(RCStorefront)
public final class Storefront: NSObject, StorefrontType {

    private let storefront: StorefrontType

    init(_ storefront: StorefrontType) {
        self.storefront = storefront

        super.init()
    }

    // Note: this class inherits its docs from `StorefrontType`
    // swiftlint:disable missing_docs

    @objc public var countryCode: String { self.storefront.countryCode }
    @objc public var identifier: String { self.storefront.identifier }

    // swiftlint:enable missing_docs

    // MARK: -

    /// Creates an instance from any `StorefrontType`.
    /// If `storefront` is already a wrapped `Storefront` then this returns it instead.
    static func from(storefront: StorefrontType) -> Storefront {
        return storefront as? Storefront
            ?? Storefront(storefront)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? StorefrontType else { return false }

        return self.identifier == other.identifier
    }

    public override var hash: Int {
        return self.identifier.hashValue
    }

    public override var description: String {
        return """
        <\(String(describing: Storefront.self)):
        identifier=\(self.identifier),
        countryCode=\(countryCode)
        >
        """
    }

}

extension Storefront: Sendable {}

public extension Storefront {

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, macCatalyst 13.1, *)
    private static var currentStorefrontType: StorefrontType? {
        get async {
            if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
                let sk2Storefront = await StoreKit.Storefront.current
                return sk2Storefront.map(SK2Storefront.init)
            } else {
                return Self.sk1CurrentStorefrontType
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, macCatalyst 13.1, *)
    internal static var sk1CurrentStorefrontType: StorefrontType? {
        return SKPaymentQueue.default().storefront.map(SK1Storefront.init)
    }

    /// The current App Store storefront for the device.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, macCatalyst 13.1, *)
    static var currentStorefront: Storefront? {
        get async {
            return await self.currentStorefrontType.map(Storefront.from(storefront: ))
        }
    }

    /// The current App Store storefront for the device obtained from StoreKit 1 only.
    @available(swift, obsoleted: 0.0.1, renamed: "currentStorefront")
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, macCatalyst 13.1, *)
    @objc static var sk1CurrentStorefront: Storefront? {
        return self.sk1CurrentStorefrontType.map(Storefront.from(storefront: ))
    }

}

// MARK: -

/// A type containing the location and unique identifier of an Apple App Store storefront.
internal protocol StorefrontType: Sendable {

    /// The three-letter code representing the country or region
    /// associated with the App Store storefront.
    /// - Note: This property uses the ISO 3166-1 Alpha-3 country code representation.
    var countryCode: String { get }

    /// A value defined by Apple that uniquely identifies an App Store storefront.
    var identifier: String { get }

}

// MARK: - Wrapper constructors / getters

extension Storefront {

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, macCatalyst 13.1, *)
    internal convenience init(sk1Storefront: SKStorefront) {
        self.init(SK1Storefront(sk1Storefront))
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    internal convenience init(sk2Storefront: StoreKit.Storefront) {
        self.init(SK2Storefront(sk2Storefront))
    }

    /// Returns the `SKStorefront` if this `Storefront` represents an `SKStorefront`.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, macCatalyst 13.1, *)
    @objc public var sk1Storefront: SKStorefront? {
        return (self.storefront as? SK1Storefront)?.underlyingSK1Storefront
    }

    /// Returns the `StoreKit.Storefront` if this `Storefront` represents a `StoreKit.Storefront`.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    public var sk2Storefront: StoreKit.Storefront? {
        return (self.storefront as? SK2Storefront)?.underlyingSK2Storefront
    }

}
