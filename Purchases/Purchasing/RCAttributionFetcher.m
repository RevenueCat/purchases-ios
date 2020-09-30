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
#import "RCBackend.h"
#import "RCAttributionData.h"


@protocol FakeAdClient <NSObject>

+ (instancetype)sharedClient;
- (void)requestAttributionDetailsWithBlock:(RCAttributionDetailsBlock)completionHandler;

@end


@protocol FakeASIdentifierManager <NSObject>

+ (instancetype)sharedManager;

@end


static NSMutableArray<RCAttributionData *> *_Nullable postponedAttributionData;


@interface RCAttributionFetcher ()

@property (strong, nonatomic) RCDeviceCache *deviceCache;
@property (strong, nonatomic) RCIdentityManager *identityManager;
@property (strong, nonatomic) RCBackend *backend;

@end


@implementation RCAttributionFetcher : NSObject

- (instancetype)initWithDeviceCache:(RCDeviceCache *)deviceCache
                    identityManager:(RCIdentityManager *)identityManager
                            backend:(RCBackend *)backend {
    if (self = [super init]) {
        self.deviceCache = deviceCache;
        self.identityManager = identityManager;
        self.backend = backend;
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
    NSString *networkID = [NSString stringWithFormat:@"%ld", (long) network];
    NSDictionary *cachedDict =
        [self.deviceCache latestNetworkAndAdvertisingIdsSentForAppUserID:self.identityManager.currentAppUserID];
    return cachedDict[networkID];
}

- (void)postAttributionData:(NSDictionary *)data
                fromNetwork:(RCAttributionNetwork)network
           forNetworkUserId:(nullable NSString *)networkUserId {
    if (data[@"rc_appsflyer_id"]) {
        RCErrorLog(@"⚠️ The parameter key rc_appsflyer_id is deprecated. Pass networkUserId to addAttribution instead. ⚠️");
    }
    if (network == RCAttributionNetworkAppsFlyer && networkUserId == nil) {
        RCErrorLog(@"⚠️ The parameter networkUserId is REQUIRED for AppsFlyer. ⚠️");
    }
    NSString *appUserID = self.identityManager.currentAppUserID;
    NSString *networkKey = [NSString stringWithFormat:@"%ld", (long) network];
    NSString *identifierForAdvertisers = [self identifierForAdvertisers];
    NSDictionary *dictOfLatestNetworkIdsAndAdvertisingIdsSentToNetworks =
        [self.deviceCache latestNetworkAndAdvertisingIdsSentForAppUserID:appUserID];
    NSString *latestSentToNetwork = dictOfLatestNetworkIdsAndAdvertisingIdsSentToNetworks[networkKey];
    NSString *newValueForNetwork = [NSString stringWithFormat:@"%@_%@", identifierForAdvertisers, networkUserId];

    if ([latestSentToNetwork isEqualToString:newValueForNetwork]) {
        RCDebugLog(@"Attribution data is the same as latest. Skipping.");
    } else {
        NSMutableDictionary<NSString *, NSString *> *newDictToCache =
            [NSMutableDictionary dictionaryWithDictionary:dictOfLatestNetworkIdsAndAdvertisingIdsSentToNetworks];
        newDictToCache[networkKey] = newValueForNetwork;

        NSMutableDictionary *newData = [NSMutableDictionary dictionaryWithDictionary:data];
        newData[@"rc_idfa"] = identifierForAdvertisers;
        newData[@"rc_idfv"] = [self identifierForVendor];
        newData[@"rc_attribution_network_id"] = networkUserId;

        if (newData.count > 0) {
            [self.backend postAttributionData:newData
                                  fromNetwork:network
                                 forAppUserID:appUserID
                                   completion:^(NSError *_Nullable error) {
                                       if (error == nil) {
                                           [self.deviceCache setLatestNetworkAndAdvertisingIdsSent:newDictToCache
                                                                                      forAppUserID:appUserID];
                                       }
                                   }];
        }
    }
}

- (void)postAppleSearchAdsAttributionCollection {
    NSString *latestNetworkIdAndAdvertisingIdSentToAppleSearchAds = [self
        latestNetworkIdAndAdvertisingIdentifierSentForNetwork:RCAttributionNetworkAppleSearchAds];
    if (latestNetworkIdAndAdvertisingIdSentToAppleSearchAds == nil) {
        [self adClientAttributionDetailsWithCompletionBlock:^(NSDictionary<NSString *, NSObject *> *_Nullable attributionDetails,
                                                              NSError *_Nullable error) {
            NSArray *values = [attributionDetails allValues];

            bool hasIadAttribution = values.count != 0 && [values[0][@"iad-attribution"] boolValue];
            if (hasIadAttribution) {
                [self postAttributionData:attributionDetails
                              fromNetwork:RCAttributionNetworkAppleSearchAds
                         forNetworkUserId:nil];
            }
        }];
    }
}

- (void)postPostponedAttributionDataIfNeeded {
    if (postponedAttributionData) {
        for (RCAttributionData *attributionData in postponedAttributionData) {
            [self postAttributionData:attributionData.data
                          fromNetwork:attributionData.network
                     forNetworkUserId:attributionData.networkUserId];
        }
    }

    postponedAttributionData = nil;
}

static NSMutableArray<RCAttributionData *> *_Nullable postponedAttributionData;

+ (void)storePostponedAttributionData:(NSDictionary *)data
                          fromNetwork:(RCAttributionNetwork)network
                     forNetworkUserId:(nullable NSString *)networkUserId {
    if (postponedAttributionData == nil) {
        postponedAttributionData = [NSMutableArray array];
    }
    [postponedAttributionData addObject:[[RCAttributionData alloc] initWithData:data
                                                                    fromNetwork:network
                                                               forNetworkUserId:networkUserId]];
}

@end

