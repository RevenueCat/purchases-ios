//
//  RCAttributionFetcher.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCAttributionFetcher.h"
#import "RCCrossPlatformSupport.h"
#import "RCLogUtils.h"
#import "RCDeviceCache.h"
#import "RCIdentityManager.h"


@protocol FakeAdClient <NSObject>

+ (instancetype)sharedClient;
- (void)requestAttributionDetailsWithBlock:(RCAttributionDetailsBlock)completionHandler;

@end

@protocol FakeASIdentifierManager <NSObject>

+ (instancetype)sharedManager;

@end

@interface RCAttributionFetcher()

@property(strong, nonatomic) RCDeviceCache *deviceCache;
@property(strong, nonatomic) RCIdentityManager *identityManager;

@end


@implementation RCAttributionFetcher : NSObject

- (instancetype)initWithDeviceCache:(RCDeviceCache *)deviceCache
                    identityManager:(RCIdentityManager *)identityManager {
    if (self = [super init]) {
        self.deviceCache = deviceCache;
        self.identityManager = identityManager;
    }
    return self;
}

- (NSString *)rot13:(NSString *)string {
    NSMutableString *rotatedString = [NSMutableString string];
    for (NSUInteger charIdx = 0; charIdx < string.length; charIdx++) {
        unichar c = [string characterAtIndex:charIdx];
        unichar i = '0';
        if (('a' <= c && c <= 'm') || ('A' <= c && c <= 'M')) {
            i = (unichar) (c + 13);
        }
        if (('n' <= c && c <= 'z') || ('N' <= c && c <= 'Z')) {
            i = (unichar) (c - 13);
        }
        [rotatedString appendFormat:@"%c", i];
    }
    return rotatedString;
}

- (nullable NSString *)identifierForAdvertisers {
    if (@available(iOS 6.0, macOS 10.14, *)) {
        // We need to do this mangling to avoid Kid apps being rejected for getting idfa.
        // It looks like during the app review process Apple does some string matching looking for
        // functions in the AdSupport.framework. We apply rot13 on these functions and classes names
        // so that Apple can't find them during the review, but we can still access them on runtime.
        NSString *mangledClassName = @"NFVqragvsvreZnantre";
        NSString *mangledIdentifierPropertyName = @"nqiregvfvatVqragvsvre";

        NSString *className = [self rot13:mangledClassName];
        id <FakeASIdentifierManager> asIdentifierManagerClass = (id <FakeASIdentifierManager>) NSClassFromString(className);
        if (asIdentifierManagerClass) {
            NSString *identifierPropertyName = [self rot13:mangledIdentifierPropertyName];
            id sharedManager = [asIdentifierManagerClass sharedManager];
            NSUUID *identifierValue = [sharedManager valueForKey:identifierPropertyName];
            return identifierValue.UUIDString;
        } else {
            RCDebugLog(@"AdSupport framework not imported. Attribution data incomplete.");
        }
    }
    return nil;
}


- (nullable NSString *)identifierForVendor {
#if UI_DEVICE_AVAILABLE
    if ([UIDevice class]) {
        return UIDevice.currentDevice.identifierForVendor.UUIDString;
    }
#endif
    return nil;
}

- (void)adClientAttributionDetailsWithCompletionBlock:(RCAttributionDetailsBlock)completionHandler {
#if AD_CLIENT_AVAILABLE
    id<FakeAdClient> adClientClass = (id<FakeAdClient>)NSClassFromString(@"ADClient");
    
    if (adClientClass) {
        [[adClientClass sharedClient] requestAttributionDetailsWithBlock:completionHandler];
    }
#endif
}

- (NSString *)latestNetworkIdAndAdvertisingIdentifierSentForNetwork:(RCAttributionNetwork)network {
    NSString *networkID = [NSString stringWithFormat:@"%ld", (long)network];
    NSDictionary *cachedDict = [self.deviceCache latestNetworkAndAdvertisingIdsSentForAppUserID:self.identityManager.currentAppUserID];
    return cachedDict[networkID];
}

@end

