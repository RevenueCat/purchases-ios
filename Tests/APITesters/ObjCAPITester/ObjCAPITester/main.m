//
//  main.m
//  MigrateTester
//
//  Created by Joshua Liebowitz on 6/18/21.
//

#import <Foundation/Foundation.h>
#import "RCAttributionAPI.h"
#import "RCAttributionNetworkAPI.h"
#import "RCConfigurationAPI.h"
#import "RCCustomerInfoAPI.h"
#import "RCEntitlementInfoAPI.h"
#import "RCEntitlementInfosAPI.h"
#import "RCIntroEligibilityAPI.h"
#import "RCNonSubscriptionTransactionAPI.h"
#import "RCOfferingAPI.h"
#import "RCOfferingsAPI.h"
#import "RCPackageAPI.h"
#import "RCPromotionalOfferAPI.h"
#import "RCPurchasesAPI.h"
#import "RCPurchasesErrorCodeAPI.h"
#import "RCRefundRequestStatusAPI.h"
#import "RCStorefrontAPI.h"
#import "RCStoreProductAPI.h"
#import "RCStoreProductDiscountAPI.h"
#import "RCSubscriptionPeriodAPI.h"
#import "RCTransactionAPI.h"

@import StoreKit;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [RCAttributionAPI checkAPI];
        [RCAttributionNetworkAPI checkEnums];

        [RCCustomerInfoAPI checkAPI];

        [RCEntitlementInfoAPI checkAPI];
        [RCEntitlementInfoAPI checkEnums];

        [RCEntitlementInfosAPI checkAPI];

        [RCIntroEligibilityAPI checkAPI];
        [RCIntroEligibilityAPI checkEnums];

        [RCNonSubscriptionTransactionAPI checkAPI];

        [RCOfferingAPI checkAPI];
        [RCOfferingsAPI checkAPI];

        [RCPackageAPI checkAPI];
        [RCPackageAPI checkEnums];

        [RCPromotionalOfferAPI checkAPI];

        [RCPurchasesAPI checkAPI];
        [RCPurchasesAPI checkConstants];
        [RCPurchasesAPI checkEnums];

        [RCConfigurationAPI checkAPI];

        [RCPurchasesErrorCodeAPI checkEnums];

        [RCRefundRequestStatusAPI checkEnums];

        [RCStorefrontAPI checkAPI];

        [RCStoreProductAPI checkAPI];

        [RCStoreProductDiscountAPI checkAPI];
        [RCStoreProductDiscountAPI checkPaymentModeEnum];

        [RCSubscriptionPeriodAPI checkAPI];
        [RCSubscriptionPeriodAPI checkUnitEnum];

        [RCTransactionAPI checkAPI];
    }
    return 0;
}
