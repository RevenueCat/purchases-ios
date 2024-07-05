//
//  PaywallPresenter.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-25.
//

import SwiftUI
import RevenueCat
@testable import RevenueCatUI

enum PaywallPresnterError: Error, CustomStringConvertible {
    case cancelled

    var description: String {
        "An error occured yo yo YO"
    }
}

struct PaywallPresenter: View {

    var offering: Offering
    var mode: PaywallViewMode
    var introEligility: IntroEligibilityStatus
    var displayCloseButton: Bool = Configuration.defaultDisplayCloseButton

    var body: some View {
        switch self.mode {
        case .fullScreen:

            let handler = PurchaseHandler.default(
                performPurchase: { package in
                var userCancelled = false
                    var error: Error? 
                    
                // do stuff

                return (userCancelled: false, error: error)

            }, performRestore: {
                var success = false
                var error: Error?

                // do stuff

                return (success: success, error: error)
            })

            let configuration = PaywallViewConfiguration(
                offering: offering,
                fonts: DefaultPaywallFontProvider(),
                displayCloseButton: displayCloseButton,
                introEligibility: .producing(eligibility: introEligility).with(delay: 30),
                purchaseHandler: handler
            )

            PaywallView(configuration: configuration)
                .onPurchaseStarted { package in
                    print(#function)
                }
                .onPurchaseCompleted { customerInfo in
                    print(#function)
                }
                .onPurchaseCancelled {
                    print(#function)
                }

//            PaywallView(performPurchase: { packageToPurchase in
//                var userCancelled = false
//                var error: Error?
//                
//                // use StoreKit to perform purchase
//
//                return (userCancelled: userCancelled, error: error)
//            }, performRestore: {
//                var success = false
//                var error: Error?
//
//                // use StoreKit to perform restore
//
//                return (success: success, error: error)
//            })

//Text("abc")
//    .paywallFooter(myAppPurchaseLogic: MyAppPurchaseLogic(performPurchase: { packageToPurchase in
//        var userCancelled = false
//        var error: Error?
//
//        // use StoreKit to perform purchase
//
//        return (userCancelled: userCancelled, error: error)
//    }, performRestore: {
//        var success = false
//        var error: Error?
//
//        // use StoreKit to perform restore
//
//        return (success: success, error: error)
//    }))



#if !os(watchOS)
        case .footer:
            CustomPaywallContent()

//                .paywallFooter(offering: self.offering,
//                               customerInfo: nil,
//                               introEligibility: .producing(eligibility: introEligility), performPurchase: { package in


                .paywallFooter(offering: self.offering, myAppPurchaseLogic: .init(performPurchase: { packageToPurchase in
                    return (userCancelled: true, error: nil)
                }, performRestore: {
                    return (success: true, error: nil)
                })) { package in

                }





                               
//                .paywallFooter(offering: self.offering,
//                               customerInfo: nil,
//                               introEligibility: .producing(eligibility: introEligility)) { package in
//                    print("purchase")
//                    // why is return not required here now
//                } performRestore: {
//                    print("restore")
//                    return (success: true, error: nil)
//                }

        case .condensedFooter:
            CustomPaywallContent()
//                .paywallFooter(offering: self.offering,
//                               customerInfo: nil,
//                               condensed: true,
//                               introEligibility: .producing(eligibility: introEligility))
#endif
        }
    }

}
