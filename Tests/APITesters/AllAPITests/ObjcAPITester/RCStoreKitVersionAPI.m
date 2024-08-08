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
    const __unused RCStoreKitVersion version = RCStoreKitVersion1;

    switch (version) {
        case RCStoreKitVersion1:
        case RCStoreKitVersion2:
            break;
    }
}

@end
