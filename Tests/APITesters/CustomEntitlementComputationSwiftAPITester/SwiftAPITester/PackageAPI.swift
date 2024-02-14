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
import RevenueCat_CustomEntitlementComputation
import StoreKit

func checkPackageAPI(pack: Package! = nil) {
    let _: String = pack.identifier
    let _: PackageType = pack.packageType
    let _: StoreProduct = pack.storeProduct
    let _: String = pack.offeringIdentifier
    let _: PresentedOfferingContext = pack.presentedOfferingContext
    let _: String = pack.localizedPriceString
    let _: String? = pack.localizedIntroductoryPriceString
}

private func checkCreatePackageAPI(product: StoreProduct) {
    _ = Package(
        identifier: "",
        packageType: PackageType.annual,
        storeProduct: product,
        offeringIdentifier: ""
    )
}

func checkPackageEnums(packageType: PackageType! = nil) {
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
