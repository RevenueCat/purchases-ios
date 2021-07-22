//
//  AttributionNetwork.swift
//  PurchasesCoreSwift
//
//  Created by César de la Vega on 6/18/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

enum AttributionNetwork: Int {
    /**
     Apple's search ads
     */
    case appleSearchAds = 0,
         /**
         Adjust https://www.adjust.com/
         */
         adjust,
         /**
         AppsFlyer https://www.appsflyer.com/
         */
         appsFlyer,
         /**
         Branch https://www.branch.io/
         */
         branch,
         /**
         Tenjin https://www.tenjin.io/
         */
         tenjin,
         /**
         Facebook https://developers.facebook.com/
         */
         facebook,
         /**
         mParticle https://www.mparticle.com/
         */
         mParticle
}
