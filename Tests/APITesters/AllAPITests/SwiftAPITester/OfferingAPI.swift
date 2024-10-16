//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingAPI.swift
//
//  Created by Madeline Beyl on 8/25/21.

import Foundation
import RevenueCat

var off: Offering!
func checkOfferingAPI() {
    struct Data: Decodable {}

    let ident: String = off.identifier
    let sDesc: String = off.serverDescription
    let aPacks: [Package] = off.availablePackages
    let lPack: Package? = off.lifetime
    let annPack: Package? = off.annual
    let smPack: Package? = off.sixMonth
    let thmPack: Package? = off.threeMonth
    let twmPack: Package? = off.twoMonth
    let mPack: Package? = off.monthly
    let wPack: Package? = off.weekly
    var pPack: Package? = off.package(identifier: "")
    pPack = off.package(identifier: nil)
    let package: Package? = off[""]
    let metadata: [String: Any] = off.metadata
    let metadataString: String = off.getMetadataValue(for: "", default: "")
    let metadataInt: Int = off.getMetadataValue(for: "", default: 0)
    let metadataOptionalInt: Int? = off.getMetadataValue(for: "", default: nil)
    let metadataDecodable: Data? = off.getMetadataValue(for: "")
    let _: PaywallData? = off.paywall

    print(off!, ident, sDesc, aPacks, lPack!, annPack!, smPack!, thmPack!, twmPack!,
          mPack!, wPack!, pPack!, package!, metadata, metadataString, metadataInt, metadataOptionalInt!,
          metadataDecodable!)
}

private func checkCreateOfferingAPI(package: Package) {
    _ = Offering(
        identifier: "",
        serverDescription: "",
        availablePackages: [package]
    )
    _ = Offering(
        identifier: "",
        serverDescription: "",
        metadata: [String: Any](),
        availablePackages: [package]
    )
    _ = Offering(
        identifier: "",
        serverDescription: "",
        paywall: Optional<PaywallData>.none,
        availablePackages: [package]
    )
    _ = Offering(
        identifier: "",
        serverDescription: "",
        metadata: [String: Any](),
        paywall: Optional<PaywallData>.none,
        availablePackages: [package]
    )
}
