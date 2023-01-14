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
    RCConfiguration *config = [[[[[[[[[[[[[builder withApiKey:@""]
                                          withObserverMode:false]
                                         withUserDefaults:NSUserDefaults.standardUserDefaults]
                                        withAppUserID:@""]
                                       withAppUserID:nil]
                                      withDangerousSettings:[[RCDangerousSettings alloc] init]]
                                     withNetworkTimeout:1]
                                    withStoreKit1Timeout: 1]
                                   withPlatformInfo:[[RCPlatformInfo alloc] initWithFlavor:@"" version:@""]]
                                  withPublicKey:NSData.new error:nil]
                                 withPublicKeyURL:NSURL.new error:nil]
                                withUsesStoreKit2IfAvailable:false] build];
    NSLog(@"%@", config);
}

@end
