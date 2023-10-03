//
//  RCAttributionAPI.m
//  ObjCAPITester
//
//  Created by Joshua Liebowitz on 6/13/22.
//

@import RevenueCat;
#import "RCAttributionAPI.h"

@implementation RCAttributionAPI

+ (void)checkAPI {
    RCAttribution *a;
    NSDictionary<NSString *, NSString *> *attributes = nil;
    [a setAttributes: attributes];
    [a setEmail: nil];
    [a setEmail: @""];
    [a setPhoneNumber: nil];
    [a setPhoneNumber: @""];
    [a setDisplayName: nil];
    [a setDisplayName: @""];
    [a setPushToken: nil];
    [a setPushToken: [@"" dataUsingEncoding: NSUTF8StringEncoding]];
    [a setPushTokenString: @""];
    [a setPushTokenString: nil];
    [a setAdjustID: nil];
    [a setAdjustID: @""];
    [a setAppsflyerID: nil];
    [a setAppsflyerID: @""];
    [a setFBAnonymousID: nil];
    [a setFBAnonymousID: @""];
    [a setMparticleID: nil];
    [a setMparticleID: @""];
    [a setOnesignalID: nil];
    [a setOnesignalID: @""];
    [a setOnesignalUserID: nil];
    [a setOnesignalUserID: @""];
    [a setCleverTapID: nil];
    [a setCleverTapID: @""];
    [a setMixpanelDistinctID: nil];
    [a setMixpanelDistinctID: @""];
    [a setFirebaseAppInstanceID: nil];
    [a setFirebaseAppInstanceID: @""];
    [a setMediaSource: nil];
    [a setMediaSource: @""];
    [a setCampaign: nil];
    [a setCampaign: @""];
    [a setAdGroup: nil];
    [a setAdGroup: @""];
    [a setAd: nil];
    [a setAd: @""];
    [a setKeyword: nil];
    [a setKeyword: @""];
    [a setCreative: nil];
    [a setCreative: @""];
    [a collectDeviceIdentifiers];
    [a enableAdServicesAttributionTokenCollection];
}

@end
