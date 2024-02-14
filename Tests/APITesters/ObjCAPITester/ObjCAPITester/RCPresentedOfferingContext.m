//
//  RCPresentedOfferingContext.m
//  ObjCAPITester
//
//  Created by Josh Holtz on 2/14/24.
//

#import "RCPresentedOfferingContext.h"

@import StoreKit;
@import RevenueCat;

@implementation RCPresentOfferingContextAPI

+ (void)checkAPI {
    RCPresentedOfferingContext *poc;
    NSString *oid = poc.offeringIdentifier;

    NSLog(poc, oid);

    RCPresentedOfferingContext *context = [[RCPresentedOfferingContext alloc] initWithOfferingIdentifier:oid];
}

@end
