//
//  PurchasesDelegateHandler.swift
//  Magic Weather SwiftUI
//
//  Created by Cody Kerns on 1/19/21.
//

import Foundation
import RevenueCat

/*
 The class we'll use to publish PurchaserInfo data to our Magic Weather app.
 */

class PurchasesDelegateHandler: NSObject, ObservableObject {
    static let shared = PurchasesDelegateHandler()
}

extension PurchasesDelegateHandler: PurchasesDelegate {
    
    /* 
     Whenever the `shared` instance of Purchases updates the PurchaserInfo cache, this method will be called.
    
     Note: PurchaserInfo is not pushed to each Purchases client, it has to be fetched. 
     This delegate method is only called when the SDK updates its cache after an app launch, purchase, restore, or fetch. 
     You still need to call `Purchases.shared.purchaserInfo` to fetch PurchaserInfo regularly.
     */
    func purchases(_ purchases: Purchases, didReceiveUpdated purchaserInfo: Purchases.PurchaserInfo) {
        
        /// - Update our published purchaserInfo object
        UserViewModel.shared.purchaserInfo = purchaserInfo
    }
}
