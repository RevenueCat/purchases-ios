//
//  BackendErrorCodes.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 7/12/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

/**
 Error codes sent by the RevenueCat backend. This only includes the errors that matter to the SDK
 */
@objc(RCBackendErrorCode) public enum BackendErrorCodes: Int, Error {

    @objc(RCBackendInvalidPlatform) case invalidPlatform = 7000
    @objc(RCBackendStoreProblem) case storeProblem = 7101
    @objc(RCBackendCannotTransferPurchase) case cannotTransferPurchase = 7102
    @objc(RCBackendInvalidReceiptToken) case invalidReceiptToken = 7103
    @objc(RCBackendInvalidAppStoreSharedSecret) case invalidAppStoreSharedSecret = 7104
    @objc(RCBackendInvalidPaymentModeOrIntroPriceNotProvided) case invalidPaymentModeOrIntroPriceNotProvided = 7105
    @objc(RCBackendProductIdForGoogleReceiptNotProvided) case productIdForGoogleReceiptNotProvided = 7106
    @objc(RCBackendInvalidPlayStoreCredentials) case invalidPlayStoreCredentials = 7107
    @objc(RCBackendInternalServerError) case internalServerError = 7110
    @objc(RCBackendEmptyAppUserId) case emptyAppUserId = 7220
    @objc(RCBackendInvalidAuthToken) case invalidAuthToken = 7224
    @objc(RCBackendInvalidAPIKey) case invalidAPIKey = 7225
    @objc(RCBackendBadRequest) case badRequest = 7226
    @objc(RCBackendPlayStoreQuotaExceeded) case playStoreQuotaExceeded = 7229
    @objc(RCBackendPlayStoreInvalidPackageName) case playStoreInvalidPackageName = 7230
    @objc(RCBackendPlayStoreGenericError) case playStoreGenericError = 7231
    @objc(RCBackendUserIneligibleForPromoOffer) case userIneligibleForPromoOffer = 7232
    @objc(RCBackendInvalidAppleSubscriptionKey) case invalidAppleSubscriptionKey = 7234
    @objc(RCBackendInvalidSubscriberAttributes) case invalidSubscriberAttributes = 7263
    @objc(RCBackendInvalidSubscriberAttributesBody) case invalidSubscriberAttributesBody = 7264

}
