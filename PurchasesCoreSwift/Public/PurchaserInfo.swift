//
//  PurchaserInfo.swift
//  PurchasesCoreSwift
//
//  Created by Madeline Beyl on 7/9/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@objc public class PurchaserInfo: NSObject {
    
    // Entitlements attached to this purchaser info
    var entitlements: EntitlementInfos?
    
    // All *subscription* product identifiers with expiration dates in the future.
    var activeSubscriptions: Set<String>? {
        get {
            // TODO implement
            return nil
        }
    }
    
    // All product identifiers purchases by the user regardless of expiration.
    let allPurchasedProductIdentifiers: Set<String> = Set()
    
    // Returns the latest expiration date of all products, nil if there are none
    var latestExpirationDate: Date? {
        get {
            // TODO implement
            return nil
        }
    }

    // Returns all product IDs of the non-subscription purchases a user has made.
    // TODO add deprecation message:  DEPRECATED_MSG_ATTRIBUTE("use nonSubscriptionTransactions");
    var nonConsumablePurchases: Set<String> = Set()
    
    
    // Returns all the non-subscription purchases a user has made.
    // The purchases are ordered by purchase date in ascending order.
    var nonSubscriptionTransactions: Array<Transaction> = Array()
    
    /**
    Returns the build number (in iOS) or the marketing version (in macOS) for the version of the application when the user bought the app.
    This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in the Info.plist file when the purchase was originally made.
    Use this for grandfathering users when migrating to subscriptions.

     
     @note This can be nil, see -[RCPurchases restoreTransactionsForAppStore:]
     */
    var originalApplicationVersion: String?
    
    /**
    Returns the purchase date for the version of the application when the user bought the app.
    Use this for grandfathering users when migrating to subscriptions.

    @note This can be nil, see -[RCPurchases restoreTransactionsForAppStore:]
     */
    var originalPurchaseDate: Date?
    
    /**
     Returns the fetch date of this Purchaser info.
     @note Can be nil if was cached before we added this
     */
    let requestDate: Date?
    
    ///The date this user was first seen in RevenueCat.
    var firstSeen: Date?
    
    // The original App User Id recorded for this user.
    var originalAppUserId: String?
    
    // URL to manage the active subscription of the user.
    // If this user has an active iOS subscription, this will point to the App Store,
    // if the user has an active Play Store subscription it will point there.
    // If there are no active subscriptions it will be null.
    // If there are multiple for different platforms, it will point to the App Store
    var managementURL: URL?
    
    // TODO figure out if these should really be private?
    private var expirationDatesByProduct: Dictionary<String, Date>?
    private var purchaseDatesByProduct: Dictionary<String, Date>?
    private let originalData: [String : Any]?
    private let schemaVersion: String?
    
    //TODO is this equivalent to dispatch_once_t
    private static var dateFormatter: DateFormatter {
        get {
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone.init(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }
    }
    
    @objc public init?(data: [String : Any]) {
        // TODO avoid force casting
        if let subscriberData: [String : Any] = data["subscriber"] as! [String : Any]? {
            if let subscriptions = subscriberData["subscriptions"] as! [String : [String : Any]]? {
        //        setUpDateFormatter()
                // TODO use method instead
                
                self.originalData = data
                
                self.schemaVersion = data["schema_version"] as! String?
                self.requestDate = PurchaserInfo.dateFormatter.date(from: ((data["request_date"] ?? "") as! String))
                
                super.init()
                self.configureWithSubscriberData(subscriberData: subscriberData, subscriptions: subscriptions)
            } else {
                return nil
            }
        } else {
            return nil
        }

    }
    
    func configureWithSubscriberData(subscriberData: [String : Any], subscriptions: [String : [String : Any]]) {
        self.initializePurchasesAndEntitlementsWithSubscriberDataSubscriptions(subscriberData: subscriberData, subscriptions: subscriptions)
        self.initializeMetadataWithSubscriberData(subscriberData: subscriberData)
    }
    
    func initializeMetadataWithSubscriberData(subscriberData: [String : Any]) {
        self.originalApplicationVersion = subscriberData["original_application_version"] as! String?

        self.originalPurchaseDate = parseDate(dateString: subscriberData["original_purchase_date"]!, withDateFormatter: PurchaserInfo.dateFormatter)

        self.firstSeen = parseDate(dateString: subscriberData["first_seen"], withDateFormatter: PurchaserInfo.dateFormatter)!

        self.originalAppUserId = subscriberData["original_app_user_id"] as! String
        self.managementURL = parseURL(urlString: subscriberData["management_url"])
    }

    func initializePurchasesAndEntitlementsWithSubscriberDataSubscriptions(subscriberData: [String : Any], subscriptions: [String : [String : Any]]) {
        let nonSubscriptionsData = subscriberData["non_subscriptions"] as! [String: [[String: Any]]]
        nonConsumablePurchases = Set.init(nonSubscriptionsData.keys)

        let transactionsFactory = TransactionsFactory.init()
        nonSubscriptionTransactions = transactionsFactory.nonSubscriptionTransactions(withSubscriptionsData: nonSubscriptionsData, dateFormatter: PurchaserInfo.dateFormatter)

        var nonSubscriptionsLatestPurchases = Dictionary<String, Dictionary<String, Any>>()
        for (productId, _) in nonSubscriptionsData {
            // TODO is there a swifty way to do this
            let arrayOfPurchases = nonSubscriptionsData[productId] as! [[String: Any]]
            if (!arrayOfPurchases.isEmpty) {
                nonSubscriptionsLatestPurchases[productId] = arrayOfPurchases[arrayOfPurchases.count - 1]
            }
        }

        var allPurchases = Dictionary<String, Dictionary<String, Any>>()
        allPurchases.merge(nonSubscriptionsLatestPurchases, uniquingKeysWith: { (_, last) in last} )
        allPurchases.merge(subscriptions ?? [:], uniquingKeysWith: { (_, last) in last} )
        let entitlements = subscriberData["entitlements"] as! [String: Any]?
        self.entitlements = EntitlementInfos.init(entitlementsData: entitlements, purchasesData: allPurchases, dateFormatter: PurchaserInfo.dateFormatter, requestDate: self.requestDate)

        self.expirationDatesByProduct = self.parseExpirationDate(expirationDates: subscriptions)
        self.purchaseDatesByProduct = self.parsePurchaseDate(purchaseDates: allPurchases)
    }
    
    func parseURL(urlString: Any) -> URL? {
        if (urlString is String) {
            return URL.init(fileURLWithPath: urlString as! String)
        }
        return nil
    }
    
    func parseDate(dateString: Any, withDateFormatter: DateFormatter) -> Date? {
        if (dateString is String) {
            return PurchaserInfo.dateFormatter.date(from: dateString as! String)
        }
        return nil
    }
    
    func parseExpirationDate(expirationDates: Dictionary<String, Dictionary<String, Any>>) -> Dictionary<String, Date> {
        return parseDatesIn(dates: expirationDates, label: "expires_date")
    }
    
    func parsePurchaseDate(purchaseDates: Dictionary<String, Dictionary<String, Any>>) -> Dictionary<String, Date> {
        return parseDatesIn(dates: purchaseDates, label: "purchase_date")
    }
    
    func parseDatesIn(dates: Dictionary<String, Dictionary<String, Any>>, label: String) -> Dictionary<String, Date> {
        var parsedDates = Dictionary<String, Date>()
        
        for (identifier, _) in dates {
            let dateString = dates[identifier]?[label]
            
            if (dateString is String) {
                let date = PurchaserInfo.dateFormatter.date(from: dateString as! String)
                if (date != nil) {
                    parsedDates[identifier] = date
                }
            } else {
                parsedDates[identifier] = nil
            }
        }
        return parsedDates
    }
}



///**
// Get the expiration date for a given product identifier. You should use Entitlements though!
//
// @param productIdentifier Product identifier for product
//
// @return The expiration date for `productIdentifier`, `nil` if product never purchased
// */
//- (nullable NSDate *)expirationDateForProductIdentifier:(NSString *)productIdentifier;
//
///**
// Get the latest purchase or renewal date for a given product identifier. You should use Entitlements though!
//
// @param productIdentifier Product identifier for subscription product
//
// @return The purchase date for `productIdentifier`, `nil` if product never purchased
// */
//- (nullable NSDate *)purchaseDateForProductIdentifier:(NSString *)productIdentifier;
//
///** Get the expiration date for a given entitlement.
//
// @param entitlementId The id of the entitlement.
//
// @return The expiration date for the passed in `entitlement`, can be `nil`
// */
//- (nullable NSDate *)expirationDateForEntitlement:(NSString *)entitlementId;
//
///**
// Get the latest purchase or renewal date for a given entitlement identifier.
//
// @param entitlementId Entitlement identifier for entitlement
//
// @return The purchase date for `entitlementId`, `nil` if product never purchased
// */
//- (nullable NSDate *)purchaseDateForEntitlement:(NSString *)entitlementId;

