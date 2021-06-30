//
//  main.m
//  MigrateTester
//
//  Created by Joshua Liebowitz on 6/18/21.
//

#import <Foundation/Foundation.h>
#import "RCEntitlementInfoAPI.h"
#import "RCEntitlementInfosAPI.h"
#import "RCPurchasesAPI.h"
#import "RCSystemInfoAPI.h"
#import "RCTransactionAPI.h"

@import StoreKit;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [RCEntitlementInfoAPI checkAPI];
        [RCEntitlementInfoAPI checkEnums];
        [RCEntitlementInfosAPI checkAPI];
        [RCPurchasesAPI checkAPI];
        [RCPurchasesAPI checkEnums];
        [RCSystemInfoAPI checkAPI];
        [RCTransactionAPI checkAPI];
    }
    return 0;
}
