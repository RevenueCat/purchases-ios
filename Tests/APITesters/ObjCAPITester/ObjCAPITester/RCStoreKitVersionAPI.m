//
//  RCStoreKitVersion.m
//  ObjCAPITester
//
//  Created by Mark Villacampa on 20/12/23.
//

@import RevenueCat;

#import "RCStoreKitVersionAPI.h"

@implementation RCStoreKitVersionAPI

+ (void)checkAPI {
    const __unused int version = RCStoreKitVersionStoreKit1;

    switch (version) {
        case RCStoreKitVersionStoreKit1:
        case RCStoreKitVersionStoreKit2:
            break;
    }
}

@end
