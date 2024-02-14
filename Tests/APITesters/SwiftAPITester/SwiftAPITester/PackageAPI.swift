//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageAPI.swift
//
//  Created by Madeline Beyl on 8/26/21.

import Foundation
import RevenueCat
import StoreKit

private var pack: Package!
func checkPackageAPI() {
    let ident: String = pack.identifier
    let pType: PackageType = pack.packageType
    let prod: StoreProduct = pack.storeProduct
    let oID: String = pack.offeringIdentifier
    let pOC: PresentedOfferingContext = pack.presentedOfferingContext
    let lps: String = pack.localizedPriceString
    let lips: String? = pack.localizedIntroductoryPriceString

    print(pack!, ident, pType, prod, pOC, oID, lps, lips!)
}

private func checkCreatePackageAPI(product: StoreProduct) {
    _ = Package(
        identifier: "",
        packageType: PackageType.annual,
        storeProduct: product,
        offeringIdentifier: ""
    )
}

private var packageType: PackageType!
func checkPackageEnums() {
    switch packageType! {
    case .custom,
         .lifetime,
         .annual,
         .sixMonth,
         .threeMonth,
         .twoMonth,
         .monthly,
         .weekly,
         .unknown:
        print(packageType!)
    @unknown default:
        fatalError()
    }
}
