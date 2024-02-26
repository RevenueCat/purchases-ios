//
//  PresentedOfferingContextAPI.swift
//  SwiftAPITester
//
//  Created by Josh Holtz on 2/14/24.
//

import Foundation
import RevenueCat
import StoreKit

func checkPresentedOfferingContextAPI(context: PresentedOfferingContext! = nil) {
    let _: String = context.offeringIdentifier
    let _: String? = context.placementIdentifier
}

private func checkCreatePresentedOfferingContextAPI() {
    let _: PresentedOfferingContext = .init(offeringIdentifier: "", placementIdentifier: "")
}
