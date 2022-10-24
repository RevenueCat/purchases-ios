//
//  RCSDKTesterAPI.m
//  ObjCAPITester
//
//  Created by Nacho Soto on 10/10/22.
//

#import "RCSDKTesterAPI.h"

@import RevenueCat;

@implementation RCSDKTesterAPI

+ (void)checkAPI {
    RCSDKTester *tester = [RCSDKTester default];

    [tester testRevenueCatIntegrationWithCompletion:^(NSError * _Nullable error) {}];
}

@end
