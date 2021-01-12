//
// Created by Andrés Boedo on 1/4/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

#import "RCPurchaserInfoManager.h"
#import "RCPurchaserInfo+Protected.h"
#import "RCDeviceCache.h"
#import "RCLogUtils.h"
#import "RCBackend.h"
#import "RCSystemInfo.h"
@import PurchasesCoreSwift;

NS_ASSUME_NONNULL_BEGIN


@interface RCPurchaserInfoManager ()

@property (nonatomic) RCPurchaserInfo *lastSentPurchaserInfo;
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
        [self.operationDispatcher dispatchOnMainThread:^{
            if (info.JSONObject) {
                NSError *jsonError = nil;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:info.JSONObject
                                                                   options:0
                                                                     error:&jsonError];
                if (jsonError == nil) {
                    [self.deviceCache cachePurchaserInfo:jsonData forAppUserID:appUserID];
                    [self sendUpdatedPurchaserInfoToDelegateIfChanged:info];
                }
            }
        }];
    }
}

- (RCPurchaserInfo *)cachedPurchaserInfoForAppUserID:(NSString *)appUserID {
    NSData *purchaserInfoData = [self.deviceCache cachedPurchaserInfoDataForAppUserID:appUserID];
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
    RCPurchaserInfo *infoFromCache = [self cachedPurchaserInfoForAppUserID:appUserID];
    if (infoFromCache) {
        [self sendUpdatedPurchaserInfoToDelegateIfChanged:infoFromCache];
    }
}

- (void)invalidatePurchaserInfoCacheForAppUserID:(NSString *)appUserID __unused {
    RCDebugLog(@"%@", RCStrings.purchaserInfo.invalidating_purchaserinfo_cache);
    [self.deviceCache clearPurchaserInfoCacheForAppUserID:appUserID];
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
                                                  [self.deviceCache clearPurchaserInfoCacheTimestampForAppUserID:appUserID];
                                              }

                                              if (completion) {
                                                  [self.operationDispatcher dispatchOnMainThread: ^{
                                                      completion(info, error);
                                                  }];
                                              }
                                          }];
    }];
}

- (void)fetchAndCachePurchaserInfoIfStaleWithAppUserID:(NSString *)appUserID
                                     isAppBackgrounded:(BOOL)isAppBackgrounded
                                            completion:(nullable RCReceivePurchaserInfoBlock)completion {
    BOOL isCacheStale = ([self.deviceCache isPurchaserInfoCacheStaleForAppUserID:appUserID
                                                              isAppBackgrounded:isAppBackgrounded]
                          || ![self cachedPurchaserInfoForAppUserID:appUserID]);
    if (isCacheStale) {
        RCDebugLog(@"%@", isAppBackgrounded
                          ? RCStrings.purchaserInfo.purchaserinfo_stale_updating_in_background
                          : RCStrings.purchaserInfo.purchaserinfo_stale_updating_in_foreground);

        [self fetchAndCachePurchaserInfoWithAppUserID:appUserID
                                    isAppBackgrounded:isAppBackgrounded
                                           completion:completion];
        RCSuccessLog(@"%@", RCStrings.purchaserInfo.purchaserinfo_updated_from_network);
    }
}

- (void)sendUpdatedPurchaserInfoToDelegateIfChanged:(RCPurchaserInfo *)info {

    if ([self.delegate respondsToSelector:@selector(purchaserInfoManagerDidReceiveUpdatedPurchaserInfo:)]) {
        @synchronized (self) {
            if (![self.lastSentPurchaserInfo isEqual:info]) {
                if (self.lastSentPurchaserInfo) {
                    RCDebugLog(@"%@", RCStrings.purchaserInfo.sending_updated_purchaserinfo_to_delegate);
                } else {
                    RCDebugLog(@"%@", RCStrings.purchaserInfo.sending_latest_purchaserinfo_to_delegate);
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
    RCPurchaserInfo *infoFromCache = [self cachedPurchaserInfoForAppUserID:appUserID];
    if (infoFromCache) {
        RCDebugLog(@"%@", RCStrings.purchaserInfo.vending_cache);
        if (completion) {
            [self.operationDispatcher dispatchOnMainThread: ^{
                completion(infoFromCache, nil);
            }];
        }
    }

    [self.systemInfo isApplicationBackgroundedWithCompletion:^(BOOL isAppBackgrounded) {
        BOOL shouldCallCompletionAfterFetching = infoFromCache == nil && completion != nil;
        if (shouldCallCompletionAfterFetching) {
            [self fetchAndCachePurchaserInfoIfStaleWithAppUserID:appUserID
                                               isAppBackgrounded:isAppBackgrounded
                                                      completion:completion];
        } else {
            [self fetchAndCachePurchaserInfoIfStaleWithAppUserID:appUserID
                                               isAppBackgrounded:isAppBackgrounded
                                                      completion:nil];
        }
    }];
}

- (void)clearPurchaserInfoCacheForAppUserID:(NSString *)appUserID {
    @synchronized (self) {
        [self.deviceCache clearPurchaserInfoCacheForAppUserID:appUserID];
        self.lastSentPurchaserInfo = nil;
    }
}

@end


NS_ASSUME_NONNULL_END