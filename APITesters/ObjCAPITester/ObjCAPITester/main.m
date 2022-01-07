//
//  main.m
//  MigrateTester
//
//  Created by Joshua Liebowitz on 6/18/21.
//

#import <Foundation/Foundation.h>
#import "RCAttributionNetworkAPI.h"
#import "RCEntitlementInfoAPI.h"
#import "RCEntitlementInfosAPI.h"
#import "RCIntroEligibilityAPI.h"
#import "RCOfferingAPI.h"
#import "RCOfferingsAPI.h"
#import "RCCustomerInfoAPI.h"
#import "RCPurchasesAPI.h"
#import "RCPurchasesErrorCodeAPI.h"
#import "RCPackageAPI.h"
#import "RCRefundRequestStatusAPI.h"
#import "RCTransactionAPI.h"
#import "RCStoreProductAPI.h"

@import StoreKit;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [RCAttributionNetworkAPI checkEnums];

        [RCEntitlementInfoAPI checkAPI];
        [RCEntitlementInfoAPI checkEnums];

        [RCEntitlementInfosAPI checkAPI];

        [RCIntroEligibilityAPI checkAPI];
        [RCIntroEligibilityAPI checkEnums];

        [RCOfferingAPI checkAPI];

        [RCOfferingsAPI checkAPI];

        [RCPackageAPI checkAPI];
        [RCPackageAPI checkEnums];

        [RCCustomerInfoAPI checkAPI];

        [RCPurchasesAPI checkAPI];
        [RCPurchasesAPI checkEnums];
        [RCPurchasesAPI checkConstants];

        [RCPurchasesErrorCodeAPI checkEnums];

        [RCRefundRequestStatusAPI checkEnums];

        [RCTransactionAPI checkAPI];

        [RCStoreProductAPI checkAPI];
    }
    return 0;
}
