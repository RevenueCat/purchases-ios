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

@import StoreKit;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [RCPurchasesAPI checkAPI];
        [RCPurchasesAPI checkEnums];
        [RCEntitlementInfoAPI checkAPI];
        [RCEntitlementInfoAPI checkEnums];
        [RCEntitlementInfosAPI checkAPI];
    }
    return 0;
}
