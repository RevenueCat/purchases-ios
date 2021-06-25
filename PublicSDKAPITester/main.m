//
//  main.m
//  MigrateTester
//
//  Created by Joshua Liebowitz on 6/18/21.
//

#import <Foundation/Foundation.h>
#import "RCEntitlementInfoAPI.h"
#import "RCPurchasesAPI.h"

@import StoreKit;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [RCPurchasesAPI checkAPI];
        [RCEntitlementInfoAPI checkAPI];
    }
    return 0;
}
