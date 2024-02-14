//
//  PresentedOfferingContextAPI.swift
//  SwiftAPITester
//
//  Created by Josh Holtz on 2/14/24.
//

import Foundation
import RevenueCat
import StoreKit

private var context: PresentedOfferingContext!
func checkPresentedOfferingContextAPI() {
    let oID: String = context.offeringIdentifier

    print(context!, oID)
}

private func checkCreatePresentedOfferingContextAPI() {
    _ = PresentedOfferingContext(offeringIdentifier: "")
}
