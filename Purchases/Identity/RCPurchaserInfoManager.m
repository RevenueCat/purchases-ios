//
// Created by Andrés Boedo on 1/4/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

#import "RCPurchaserInfoManager.h"
#import "RCBackend.h"
@import PurchasesCoreSwift;

NS_ASSUME_NONNULL_BEGIN


@interface RCPurchaserInfoManager ()

@property (nonatomic, nullable) RCPurchaserInfo *lastSentPurchaserInfo;
@property (nonatomic) RCOperationDispatcher *operationDispatcher;
@property (nonatomic) RCDeviceCache *deviceCache;
@property (nonatomic) RCBackend *backend;
@property (nonatomic) RCSystemInfo *systemInfo;

@end


@implementation RCPurchaserInfoManager

@synthesize delegate = _delegate;

- (void)setDelegate:(nullable id <RCPurchaserInfoManagerDelegate>)delegate {
    _delegate = delegate;
}

- (instancetype)initWithOperationDispatcher:(RCOperationDispatcher *)operationDispatcher
                                deviceCache:(RCDeviceCache *)deviceCache
                                    backend:(RCBackend *)backend
                                 systemInfo:(RCSystemInfo *)systemInfo {
    self = [super init];
    if (self) {
        self.operationDispatcher = operationDispatcher;
        self.deviceCache = deviceCache;
        self.backend = backend;
        self.systemInfo = systemInfo;
    }

    return self;
}

- (void)cachePurchaserInfo:(RCPurchaserInfo *)info forAppUserID:(NSString *)appUserID {
    if (info) {
        NSDictionary *infoAsJSONDict = info.JSONObject;
        if ([NSJSONSerialization isValidJSONObject:infoAsJSONDict]) {
            NSError *jsonError = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoAsJSONDict
                                                               options:0
                                                                 error:&jsonError];
            if (jsonError == nil) {
                [self.deviceCache cachePurchaserInfoDataForAppUserID:jsonData appUserID:appUserID];
                [self sendUpdatedPurchaserInfoToDelegateIfChanged:info];
            }
        }
    }
}

- (nullable RCPurchaserInfo *)cachedPurchaserInfoForAppUserID:(NSString *)appUserID {
    NSData *purchaserInfoData = [self.deviceCache cachedPurchaserInfoDataWithAppUserID:appUserID];
    if (purchaserInfoData) {
        NSError *jsonError;
        NSDictionary *infoDict = [NSJSONSerialization JSONObjectWithData:purchaserInfoData options:0 error:&jsonError];
        if (jsonError == nil && infoDict != nil) {
            RCPurchaserInfo *info = [[RCPurchaserInfo alloc] initWithData:infoDict];
            if (info.schemaVersion != nil && [info.schemaVersion isEqual:[RCPurchaserInfo currentSchemaVersion]]) {
                return info;
            }
        }
    }
    return nil;
}

- (void)sendCachedPurchaserInfoIfAvailableForAppUserID:(NSString *)appUserID {
    RCPurchaserInfo * _Nullable infoFromCache = [self cachedPurchaserInfoForAppUserID:appUserID];
    if (infoFromCache) {
        [self sendUpdatedPurchaserInfoToDelegateIfChanged:infoFromCache];
    }
}

- (void)invalidatePurchaserInfoCacheForAppUserID:(NSString *)appUserID __unused {
    [RCLog debug:[NSString stringWithFormat:@"%@", RCStrings.purchaserInfo.invalidating_purchaserinfo_cache]];
    [self.deviceCache clearPurchaserInfoCacheWithAppUserID:appUserID];
}

- (void)fetchAndCachePurchaserInfoWithAppUserID:(NSString *)appUserID
                              isAppBackgrounded:(BOOL)isAppBackgrounded
                                     completion:(nullable RCReceivePurchaserInfoBlock)completion {
    [self.deviceCache setPurchaserInfoCacheTimestampToNowForAppUserID:appUserID];
    [self.operationDispatcher dispatchOnWorkerThreadWithRandomDelay:isAppBackgrounded block:^{
        [self.backend getSubscriberDataWithAppUserID:appUserID
                                          completion:^(RCPurchaserInfo *_Nullable info,
                                                       NSError *_Nullable error) {
                                              if (error == nil) {
                                                  [self cachePurchaserInfo:info forAppUserID:appUserID];
                                              } else {
                                                  [self.deviceCache clearPurchaserInfoCacheTimestampWithAppUserID:appUserID];
                                              }

                                              if (completion) {
                                                  [self.operationDispatcher dispatchOnMainThread:^{
                                                      completion(info, error);
                                                  }];
                                              }
                                          }];
    }];
}

- (void)fetchAndCachePurchaserInfoIfStaleWithAppUserID:(NSString *)appUserID
                                     isAppBackgrounded:(BOOL)isAppBackgrounded
                                            completion:(nullable RCReceivePurchaserInfoBlock)completion {
    RCPurchaserInfo * _Nullable cachedPurchaserInfo = [self cachedPurchaserInfoForAppUserID:appUserID];
    BOOL isCacheStale = [self.deviceCache isPurchaserInfoCacheStaleWithAppUserID:appUserID
                                                               isAppBackgrounded:isAppBackgrounded];
    BOOL needsToRefresh = isCacheStale || !cachedPurchaserInfo;
    if (needsToRefresh) {
        [RCLog debug:[NSString stringWithFormat:@"%@", isAppBackgrounded
                          ? RCStrings.purchaserInfo.purchaserinfo_stale_updating_in_background
                          : RCStrings.purchaserInfo.purchaserinfo_stale_updating_in_foreground]];

        [self fetchAndCachePurchaserInfoWithAppUserID:appUserID
                                    isAppBackgrounded:isAppBackgrounded
                                           completion:completion];
        [RCLog rcSuccess:[NSString stringWithFormat:@"%@", RCStrings.purchaserInfo.purchaserinfo_updated_from_network]];
    } else {
        if (completion) {
            [self.operationDispatcher dispatchOnMainThread:^{
                completion(cachedPurchaserInfo, nil);
            }];
        }
    }
}

- (void)sendUpdatedPurchaserInfoToDelegateIfChanged:(RCPurchaserInfo *)info {

    if ([self.delegate respondsToSelector:@selector(purchaserInfoManagerDidReceiveUpdatedPurchaserInfo:)]) {
        @synchronized (self) {
            if (![self.lastSentPurchaserInfo isEqual:info]) {
                if (self.lastSentPurchaserInfo) {
                    [RCLog debug:[NSString stringWithFormat:@"%@",
                                  RCStrings.purchaserInfo.sending_updated_purchaserinfo_to_delegate]];
                } else {
                    [RCLog debug:[NSString stringWithFormat:@"%@",
                                  RCStrings.purchaserInfo.sending_latest_purchaserinfo_to_delegate]];
                }
                self.lastSentPurchaserInfo = info;
                [self.operationDispatcher dispatchOnMainThread:^{
                    [self.delegate purchaserInfoManagerDidReceiveUpdatedPurchaserInfo:info];
                }];
            }
        }
    }
}

- (void)purchaserInfoWithAppUserID:(NSString *)appUserID
                   completionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    RCPurchaserInfo * _Nullable infoFromCache = [self cachedPurchaserInfoForAppUserID:appUserID];
    BOOL completionCalled = NO;
    if (infoFromCache) {
        [RCLog debug:[NSString stringWithFormat:@"%@", RCStrings.purchaserInfo.vending_cache]];
        if (completion) {
            completionCalled = YES;
            [self.operationDispatcher dispatchOnMainThread:^{
                completion(infoFromCache, nil);
            }];
        }
    }

    // prevent calling completion twice
    RCReceivePurchaserInfoBlock _Nullable fetchPurchaserInfoCompletion = completionCalled ? nil : completion;

    [self.systemInfo isApplicationBackgroundedWithCompletion:^(BOOL isAppBackgrounded) {
        [self fetchAndCachePurchaserInfoIfStaleWithAppUserID:appUserID
                                           isAppBackgrounded:isAppBackgrounded
                                                  completion:fetchPurchaserInfoCompletion];
    }];
}

- (void)clearPurchaserInfoCacheForAppUserID:(NSString *)appUserID {
    [RCLog debug:[NSString stringWithFormat:@"%@", RCStrings.purchaserInfo.invalidating_purchaserinfo_cache]];
    @synchronized (self) {
        [self.deviceCache clearPurchaserInfoCacheWithAppUserID:appUserID];
        self.lastSentPurchaserInfo = nil;
    }
}

@end


NS_ASSUME_NONNULL_END
