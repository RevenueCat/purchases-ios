import Foundation
import RevenueCat
import SwiftUI

/// `UserViewModel` contains all the logic to fetch and purchase products and keep track of the user's subscription status.
/// This class follows RevenueCat's best practices, and you can use it as a reference for you own app's implemenation.
@MainActor @Observable final class UserViewModel {
    /* The latest CustomerInfo from RevenueCat. Updated by the `customerInfoStream` in the initializer. */
    var customerInfo: CustomerInfo? {
        didSet {
            guard let entitlementIdentifier = Constants.entitlementIdentifier else { return }
            subscriptionActive = customerInfo?.entitlements[entitlementIdentifier]?.isActive == true
        }
    }

    /* The latest offerings */
    var offerings: Offerings?

    /* Checks if a subscription is active for a given entitlement */
    var subscriptionActive: Bool = false

    var isFetchingOfferings: Bool = false

    var isPurchasing: Bool = false

    init() {
        // Configure the SDK with the API Key
        Purchases.configure(withAPIKey: Constants.apiKey)
        /* Listen to changes in the `customerInfo` object using an `AsyncStream` */
        Task {
            for await newCustomerInfo in Purchases.shared.customerInfoStream {
                await MainActor.run { customerInfo = newCustomerInfo }
            }
        }
    }

    func purchase(_ product: StoreProduct) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(product: product)

            guard !userCancelled else { return }

            self.customerInfo = customerInfo
        } catch {
            print("Failed to purchase product with error: \(error)")
        }
    }

    func purchase(_ package: Package) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)

            guard !userCancelled else { return }

            self.customerInfo = customerInfo
        } catch {
            print("Failed to purchase package with error: \(error)")
        }
    }

    func fetchOfferings() async {
        isFetchingOfferings = true
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            print(error)
        }
        isFetchingOfferings = false
    }

    func fetchStoreProducts(withIdentifiers productIdentifiers: [String]) async -> [StoreProduct] {
        await Purchases.shared.products(productIdentifiers)
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
