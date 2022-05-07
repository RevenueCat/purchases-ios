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
    RCConfigurationBuilder *builder = [RCConfiguration configurationBuilderWithAPIKey:@""];
    RCConfiguration *config = [[[[[[[[[builder withApiKey:@""]
                                      withObserverMode:false]
                                     withUserDefaults:NSUserDefaults.standardUserDefaults]
                                    withAppUserID:@""]
                                   withDangerousSettings:[[RCDangerousSettings alloc] init]]
                                  withNetworkTimeoutSeconds:1]
                                 withStoreKit1TimeoutSeconds: 1]
                                withUsesStoreKit2IfAvailable:false] build];
    NSLog(@"%@", config);
}

@end
