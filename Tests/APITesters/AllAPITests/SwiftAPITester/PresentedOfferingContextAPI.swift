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
    let _: PresentedOfferingContext.TargetingContext? = context.targetingContext
}

private func checkCreatePresentedOfferingContextAPI() {
    let _: PresentedOfferingContext = .init(offeringIdentifier: "")
    let _: PresentedOfferingContext = .init(offeringIdentifier: "",
                                            placementIdentifier: "",
                                            targetingContext: .init(revision: 1, ruleId: ""))
}

func checkTargetingContextAPI(context: PresentedOfferingContext.TargetingContext! = nil) {
    let _: Int = context.revision
    let _: String? = context.ruleId
}

private func checkTargetingContextAPI() {
    let _: PresentedOfferingContext.TargetingContext = .init(revision: 1, ruleId: "")
}
