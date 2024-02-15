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
                                                   withObserverMode:false storeKitVersion:RCStoreKitVersion2]
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
}

@end
