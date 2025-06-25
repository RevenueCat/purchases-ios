//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyInfo.swift
//
//  Created by RevenueCat on 3/19/24.

import Foundation

/**
 * Information about a virtual currency available in an offering.
 */
@objc(RCVirtualCurrencyMetadata) public final class VirtualCurrencyMetadata: NSObject {

    /**
     * The name of the virtual currency.
     */
    @objc public let name: String

    /**
     * The description of the virtual currency.
     */
    @objc public let currencyDescription: String

    @objc
    public init(name: String, description: String) {
        self.name = name
        self.currencyDescription = description
        super.init()
    }

    public override var description: String {
        return """
        <VirtualCurrencyMetadata {
            name=\(self.name),
            currencyDescription=\(self.currencyDescription)
        }>
        """
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? VirtualCurrencyMetadata else { return false }

        return self.name == other.name &&
               self.currencyDescription == other.currencyDescription
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.name)
        hasher.combine(self.currencyDescription)

        return hasher.finalize()
    }

}

extension VirtualCurrencyMetadata: Codable, Sendable {}
