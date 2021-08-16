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
#import "RCPurchaserInfoAPI.h"
#import "RCPurchasesAPI.h"
#import "RCTransactionAPI.h"
#import "RCPurchasesErrorUtilsAPI.h"
#import "RCPackageAPI.h"

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
        
        [RCPurchaserInfoAPI checkAPI];

        [RCPurchasesAPI checkAPI];
        [RCPurchasesAPI checkEnums];
        [RCPurchasesAPI checkConstants];

        [RCPurchasesErrorUtilsAPI checkAPI];

        [RCTransactionAPI checkAPI];

        // TODO test RCBackendErrorCodes, RCPurchasesErrorCode

    }
    return 0;
}
