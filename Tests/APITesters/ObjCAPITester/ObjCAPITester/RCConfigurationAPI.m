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
    RCConfiguration *config __unused = [[[[[[[[[[[[builder withApiKey:@""]
                                                  withObserverMode:false]
                                                 withUserDefaults:NSUserDefaults.standardUserDefaults]
                                                withBundle:NSBundle.mainBundle]
                                               withAppUserID:@""]
                                              withAppUserID:nil]
                                             withDangerousSettings:[[RCDangerousSettings alloc] init]]
                                            withNetworkTimeout:1]
                                           withStoreKit1Timeout: 1]
                                          withPlatformInfo:[[RCPlatformInfo alloc] initWithFlavor:@"" version:@""]]
                                         withUsesStoreKit2IfAvailable:false] build];

    if (@available(iOS 13.0, *)) {
        RCConfiguration *config __unused = [[builder withEntitlementVerificationMode:RCEntitlementVerificationModeEnforced]
                                   build];
    }
}

@end
