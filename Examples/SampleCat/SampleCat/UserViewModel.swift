import Foundation
import RevenueCat
import SwiftUI

@MainActor @Observable final class UserViewModel {
    
    /* The latest CustomerInfo from RevenueCat. Updated by the `customerInfoStream` in the initializer. */
    var customerInfo: CustomerInfo? {
        didSet {
            subscriptionActive = customerInfo?.entitlements[Constants.entitlementID]?.isActive == true
        }
    }
    
    /* The latest offerings */
    var offerings: Offerings? = nil
    
    /* Checks if a subscription is active for a given entitlement */
    var subscriptionActive: Bool = false
    
    init() {
            /* Listen to changes in the `customerInfo` object using an `AsyncStream` */
            Task {
                for await newCustomerInfo in Purchases.shared.customerInfoStream {
                    await MainActor.run { customerInfo = newCustomerInfo }
                }
            }
        }
    
    /*
     How to login and identify your users with the Purchases SDK.
     
     These functions mimic displaying a login dialog, identifying the user, then logging out later.
     
     Read more about Identifying Users here: https://docs.revenuecat.com/docs/user-ids
     */
    #warning("Public-facing usernames aren't optimal for user ID's - you should use something non-guessable, like a non-public database ID. For more information, visit https://docs.revenuecat.com/docs/user-ids.")
    func login(userId: String) async {
        _ = try? await Purchases.shared.logIn(userId)
    }
    
    func logout() async {
        /**
         The current user ID is no longer valid for your instance of *Purchases* since the user is logging out, and is no longer authorized to access customerInfo for that user ID.
         
         `logOut` clears the cache and regenerates a new anonymous user ID.
         
         - Note: Each time you call `logOut`, a new installation will be logged in the RevenueCat dashboard as that metric tracks unique user ID's that are in-use. Since this method generates a new anonymous ID, it counts as a new user ID in-use.
         */
        _ = try? await Purchases.shared.logOut()
    }
}
