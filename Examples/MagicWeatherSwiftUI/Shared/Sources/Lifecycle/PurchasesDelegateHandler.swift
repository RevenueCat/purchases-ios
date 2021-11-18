//
//  PurchasesDelegateHandler.swift
//  Magic Weather SwiftUI
//
//  Created by Cody Kerns on 1/19/21.
//

import Foundation
import RevenueCat

/*
 The class we'll use to publish CustomerInfo data to our Magic Weather app.
 */

class PurchasesDelegateHandler: NSObject, ObservableObject {
    static let shared = PurchasesDelegateHandler()
}

extension PurchasesDelegateHandler: PurchasesDelegate {
    
    /**
     Whenever the `shared` instance of Purchases updates the CustomerInfo cache, this method will be called.
    
     - Note: CustomerInfo is not pushed to each Purchases client, it has to be fetched.
     This delegate method is only called when the SDK updates its cache after an app launch, purchase, restore, or fetch. 
     You still need to call `Purchases.shared.customerInfo` to fetch CustomerInfo regularly.
     */
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        
        /// - Update our published customerInfo object
        UserViewModel.shared.customerInfo = customerInfo
    }
}
