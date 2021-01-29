//
//  UserViewModel.swift
//  Magic Weather SwiftUI
//
//  Created by Cody Kerns on 1/19/21.
//

import Foundation
import Purchases
import SwiftUI

/* Static shared model for UserView */
class UserViewModel: NSObject, ObservableObject {
    static let shared = UserViewModel()
    
    /* The latest PurchaserInfo from RevenueCat. Updated by PurchasesDelegate whenever the Purchases SDK updates the cache */
    @Published var purchaserInfo: Purchases.PurchaserInfo? {
        didSet {
            subscriptionActive = purchaserInfo?.entitlements[Constants.entitlementID]?.isActive == true
        }
    }
    
    /* The latest offerings - fetched from MagicWeatherApp.swift on app launch */
    @Published var offerings: Purchases.Offerings? = nil
    
    /* Set from the didSet method of purchaserInfo above, based on the entitlement set in Constants.swift */
    @Published var subscriptionActive: Bool = false
    
    /*
     How to login and identify your users with the Purchases SDK.
     
     These functions mimic displaying a login dialog, identifying the user, then logging out later.
     
     Read more about Identifying Users here: https://docs.revenuecat.com/docs/user-ids
     */
    #warning("Public-facing usernames aren't optimal for user ID's - you should use something non-guessable, like a non-public database ID. For more information, visit https://docs.revenuecat.com/docs/user-ids.")
    func login(userId: String) {
        Purchases.shared.identify(userId, nil)
    }
    
    func logout() {
        /*
         The current user ID is no longer valid for your instance of *Purchases* since the user is logging out, and is no longer authorized to access purchaserInfo for that user ID.
         
         `reset` clears the cache and regenerates a new anonymous user ID.
         
         Note: Each time you call `reset`, a new installation will be logged in the RevenueCat dashboard as that metric tracks unique user ID's that are in-use. Since this method generates a new anonymous ID, it counts as a new user ID in-use.
         */
        Purchases.shared.reset(nil)
    }
}
