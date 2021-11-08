//
//  RCAttributionPoster.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2021 RevenueCat. All rights reserved.
//

#import "RCAttributionPoster.h"
#import "RCAttributionFetcher.h"
#import "RCCrossPlatformSupport.h"
#import "RCLogUtils.h"
#import "RCDeviceCache.h"
#import "RCIdentityManager.h"
#import "RCBackend.h"
#import "RCAttributionData.h"
#import "RCSystemInfo.h"
#import "RCSubscriberAttributesManager.h"
@import PurchasesCoreSwift;

static NSMutableArray<RCAttributionData *> *_Nullable postponedAttributionData;


@interface RCAttributionPoster ()

@property (strong, nonatomic) RCDeviceCache *deviceCache;
@property (strong, nonatomic) RCIdentityManager *identityManager;
@property (strong, nonatomic) RCBackend *backend;
@property (strong, nonatomic) RCSystemInfo *systemInfo;
@property (strong, nonatomic) RCAttributionFetcher *attributionFetcher;
@property (strong, nonatomic) RCSubscriberAttributesManager *subscriberAttributesManager;

@end

@implementation RCAttributionPoster : NSObject

- (instancetype)initWithDeviceCache:(RCDeviceCache *)deviceCache
                    identityManager:(RCIdentityManager *)identityManager
                            backend:(RCBackend *)backend
                         systemInfo:(RCSystemInfo *)systemInfo
                 attributionFetcher:(RCAttributionFetcher *)attributionFetcher
        subscriberAttributesManager:(RCSubscriberAttributesManager *)subscriberAttributesManager {
    if (self = [super init]) {
        self.deviceCache = deviceCache;
        self.identityManager = identityManager;
        self.backend = backend;
        self.systemInfo = systemInfo;
        self.attributionFetcher = attributionFetcher;
        self.subscriberAttributesManager = subscriberAttributesManager;
    }
    return self;
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
        RCWarnLog(@"%@", RCStrings.attribution.appsflyer_id_deprecated);
    }
    if (network == RCAttributionNetworkAppsFlyer && networkUserId == nil) {
        RCWarnLog(@"%@", RCStrings.attribution.networkuserid_required_for_appsflyer);
    }
    NSString *appUserID = self.identityManager.currentAppUserID;
    NSString *networkKey = [NSString stringWithFormat:@"%ld", (long) network];
    NSString *identifierForAdvertisers = [self.attributionFetcher identifierForAdvertisers];
    NSDictionary *dictOfLatestNetworkIdsAndAdvertisingIdsSentToNetworks =
        [self.deviceCache latestNetworkAndAdvertisingIdsSentForAppUserID:appUserID];
    NSString *latestSentToNetwork = dictOfLatestNetworkIdsAndAdvertisingIdsSentToNetworks[networkKey];
    NSString *newValueForNetwork = [NSString stringWithFormat:@"%@_%@", identifierForAdvertisers, networkUserId];

    if ([latestSentToNetwork isEqualToString:newValueForNetwork]) {
        RCDebugLog(@"%@", RCStrings.attribution.skip_same_attributes);
    } else {
        NSMutableDictionary<NSString *, NSString *> *newDictToCache =
            [NSMutableDictionary dictionaryWithDictionary:dictOfLatestNetworkIdsAndAdvertisingIdsSentToNetworks];
        newDictToCache[networkKey] = newValueForNetwork;

        NSMutableDictionary *newData = [NSMutableDictionary dictionaryWithDictionary:data];
        newData[@"rc_idfa"] = identifierForAdvertisers;
        newData[@"rc_idfv"] = [self.attributionFetcher identifierForVendor];
        newData[@"rc_attribution_network_id"] = networkUserId;

        if (newData.count > 0) {
            if (network == RCAttributionNetworkAppleSearchAds) {
                [self.backend postAttributionData:newData
                                      fromNetwork:network
                                     forAppUserID:appUserID
                                       completion:^(NSError *_Nullable error) {
                                           if (error == nil) {
                                               [self.deviceCache setLatestNetworkAndAdvertisingIdsSent:newDictToCache
                                                                                          forAppUserID:appUserID];
                                           }
                                       }];
            } else {
                [self.subscriberAttributesManager convertAttributionDataAndSetAsSubscriberAttributes:newData
                                                                                             network:network
                                                                                           appUserID:appUserID];
                [self.deviceCache setLatestNetworkAndAdvertisingIdsSent:newDictToCache
                                                           forAppUserID:appUserID];
            }
        }
    }
}

- (void)postAppleSearchAdsAttributionIfNeeded {
    if (!self.attributionFetcher.isAuthorizedToPostSearchAds) {
        return;
    }

    NSString *latestNetworkIdAndAdvertisingIdSentToAppleSearchAds = [self
            latestNetworkIdAndAdvertisingIdentifierSentForNetwork:RCAttributionNetworkAppleSearchAds];
    if (latestNetworkIdAndAdvertisingIdSentToAppleSearchAds != nil) {
        return;
    }

    [self.attributionFetcher afficheClientAttributionDetailsWithCompletionBlock:^(NSDictionary<NSString *, NSObject *> *_Nullable attributionDetails,
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

