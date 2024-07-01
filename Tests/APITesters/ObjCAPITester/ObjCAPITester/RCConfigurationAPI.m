//
//  RCConfigurationAPI.m
//  ObjCAPITester
//
//  Created by Joshua Liebowitz on 5/6/22.
//

#import "RCConfigurationAPI.h"

@import RevenueCat;

@implementation RCConfigurationAPI

+ (void)checkAPI {
    RCConfigurationBuilder *builder = [RCConfiguration builderWithAPIKey:@""];
    RCConfiguration *config __unused = [[[[[[[[[[[[[builder withApiKey:@""]
                                                   withPurchasesAreCompletedBy:RCPurchasesAreCompletedByRevenueCat storeKitVersion:RCStoreKitVersion2]
                                                  withUserDefaults:NSUserDefaults.standardUserDefaults]
                                                 withAppUserID:@""]
                                                withAppUserID:nil]
                                               withDangerousSettings:[[RCDangerousSettings alloc] initWithAutoSyncPurchases:true]]
                                              withNetworkTimeout:1]
                                             withStoreKit1Timeout: 1]
                                            withPlatformInfo:[[RCPlatformInfo alloc] initWithFlavor:@"" version:@""]]
                                           withUsesStoreKit2IfAvailable:false]
                                          withStoreKitVersion:RCStoreKitVersion2]
                                         withEntitlementVerificationMode:RCEntitlementVerificationModeInformational]
                                        build];

    if (@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)) {
        RCConfiguration *config __unused = [[builder
                                             withEntitlementVerificationMode:RCEntitlementVerificationModeInformational]                                            build];
    }

    if (@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)) {
        RCConfiguration *config __unused = [[builder withDiagnosticsEnabled:true] build];
    }
}

@end
