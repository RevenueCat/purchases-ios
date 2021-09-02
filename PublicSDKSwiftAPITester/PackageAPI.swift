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
import Purchases

var pack: Purchases.Package!
func checkPackageAPI() {
    let ident: String = pack.identifier
    let pType: Purchases.PackageType = pack.packageType
    let prod: SKProduct = pack.product
    let lps: String = pack.localizedPriceString
    let lips: String = pack.localizedIntroductoryPriceString

    print(pack!, ident, pType, prod, lps, lips)
}

func checkPackageEnums() {
    var type: Purchases.PackageType = Purchases.PackageType.unknown
    type = Purchases.PackageType.custom
    type = Purchases.PackageType.lifetime
    type = Purchases.PackageType.annual
    type = Purchases.PackageType.sixMonth
    type = Purchases.PackageType.threeMonth
    type = Purchases.PackageType.twoMonth
    type = Purchases.PackageType.monthly
    type = Purchases.PackageType.weekly

    print(type)
}
