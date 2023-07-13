//
//  Logger.swift
//  
//
//  Created by Nacho Soto on 7/12/23.
//

import RevenueCat

enum Logger {

    static func warning(_ text: String) {
        // Note: this isn't ideal.
        // Once we can use the `package` keyword it can use the internal `Logger`.
        Purchases.logHandler(.warn, text)
    }

}
