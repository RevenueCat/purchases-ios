//
//  UserViewModel.swift
//  Magic Weather SwiftUI
//
//  Created by Cody Kerns on 1/19/21.
//

import Foundation
import RevenueCat
import SwiftUI

/* Static shared model for UserView */
class UserViewModel: ObservableObject {
    static let shared = UserViewModel()
    
    /* The latest CustomerInfo from RevenueCat. Updated by the `customerInfoStream` in the initializer. */
    @Published var customerInfo: CustomerInfo? {
        didSet {
            subscriptionActive = customerInfo?.entitlements[Constants.entitlementID]?.isActive == true
        }
    }
    
    /* The latest offerings - fetched from MagicWeatherApp.swift on app launch */
    @Published var offerings: Offerings? = nil
    
    /* Set from the didSet method of customerInfo above, based on the entitlement set in Constants.swift */
    @Published var subscriptionActive: Bool = false
    
    private init() {
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
    @Published var loginError: String? = nil

    func loginWithAppleIDToken(_ idToken: String) async {
        do {
            try await Purchases.shared.loginUser(with: .apple(idToken: idToken))
        } catch {
            await MainActor.run { loginError = error.localizedDescription }
        }
    }

    func logout() async {
        _ = try? await Purchases.shared.logOut()
    }
}
