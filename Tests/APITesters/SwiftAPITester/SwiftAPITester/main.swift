//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  main.swift
//
//  Created by Madeline Beyl on 9/7/21.

import Foundation

func main() -> Int {
    checkAttributionAPI()

    checkAttributionNetworkEnums()

    checkEntitlementInfoAPI()
    checkEntitlementInfoEnums()
    checkEntitlementInfosAPI()

    checkIntroEligibilityAPI()
    checkIntroEligibilityEnums()

    checkOfferingAPI()

    checkOfferingsAPI()

    checkCustomerInfoAPI()

    checkPromotionalOfferAPI()

    checkPurchasesAPI()

    checkConfigurationAPI()

    checkPurchasesEnums()

    checkPurchasesErrorCodeEnums()

    checkPackageAPI()
    checkPackageEnums()

    checkReceiptParserAPI()
    checkAppleReceiptAPI()

    checkRefundRequestStatusEnum()

    checkNonSubscriptionTransactionAPI()
    checkTransactionAPI()

    checkStoreProductAPI()
    checkStoreProductDiscountAPI()

    checkTestStoreProductAPI()
    checkTestStoreProductDiscountAPI()

    checkPaymentModeEnum()

    checkSubscriptionPeriodAPI()
    checkSubscriptionPeriodUnit()

    checkStorefrontAPI()

    checkVerificationResultAPI()

    return 0
}
