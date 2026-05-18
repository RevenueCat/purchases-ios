//
//  UserViewModel.swift
//  Magic Weather SwiftUI
//
//  Created by Cody Kerns on 1/19/21.
//

import Combine
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
            refreshIAMState()
        }
    }

    /* The latest offerings - fetched from MagicWeatherApp.swift on app launch */
    @Published var offerings: Offerings? = nil

    /* Set from the didSet method of customerInfo above, based on the entitlement set in Constants.swift */
    @Published var subscriptionActive: Bool = false

    @Published var appUserID: String = ""
    @Published var idTokenClaims: IDTokenClaims? = nil
    @Published var isAnonymous: Bool = true

    private var cancellables = Set<AnyCancellable>()

    private init() {
        /* Listen to changes in the `customerInfo` object using an `AsyncStream` */
        Task {
            for await newCustomerInfo in Purchases.shared.customerInfoStream {
                await MainActor.run { customerInfo = newCustomerInfo }
            }
        }

        /* Refresh IAM state when JWT claims are verified (e.g. after Keychain session restore). */
        NotificationCenter.default
            .publisher(for: Notification.Name("RevenueCat.IAMClaimsUpdated"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshIAMState() }
            .store(in: &cancellables)
    }

    private func refreshIAMState() {
        appUserID = Purchases.shared.appUserID
        idTokenClaims = Purchases.shared.idTokenClaims
        isAnonymous = Purchases.shared.isAnonymous
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
        await MainActor.run {
            customerInfo = nil
            idTokenClaims = nil
            appUserID = ""
            isAnonymous = true
            subscriptionActive = false
            loginError = nil
        }

        _ = try? await Purchases.shared.logOut()

        do {
            Purchases.shared.invalidateCustomerInfoCache()
            try await Purchases.shared.initAnonymous()
        } catch {
            print("Error initializing anonymous session after logout: \(error)")
        }
    }
}
