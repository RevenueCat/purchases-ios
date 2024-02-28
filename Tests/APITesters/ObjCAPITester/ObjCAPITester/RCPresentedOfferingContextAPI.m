//
//  RCPresentedOfferingContextAPI.m
//  ObjCAPITester
//
//  Created by Josh Holtz on 2/14/24.
//

#import "RCPresentedOfferingContextAPI.h"

@import StoreKit;
@import RevenueCat;

@implementation RCPresentOfferingContextAPI

+ (void)checkAPI {
    RCPresentedOfferingContext *poc = [[RCPresentedOfferingContext alloc] initWithOfferingIdentifier:@""];
    poc = [[RCPresentedOfferingContext alloc] initWithOfferingIdentifier:@"" placementIdentifier:nil targetingContext:nil];
    poc = [[RCPresentedOfferingContext alloc] initWithOfferingIdentifier:@"" 
                                                     placementIdentifier:@""
                                                        targetingContext:[[RCTargetingContext alloc] initWithRevision:1 
                                                                                                               ruleId:@""]];
    NSString *oid = poc.offeringIdentifier;
    NSString *pid = poc.placementIdentifier;

    NSLog(poc, oid, pid);
}

@end
