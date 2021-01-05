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

//@synthesize delegate = _delegate; // needs new delegate
//
//- (void)setDelegate:(id <RCPurchasesDelegate>)delegate {
//_delegate = delegate;
//RCDebugLog(@"%@", RCStrings.configure.delegate_set);
//
//[self sendCachedPurchaserInfoIfAvailable];
//}


@implementation RCPurchaserInfoManager

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
                }
            }
        }];
    }
}

- (RCPurchaserInfo *)readPurchaserInfoFromCacheForAppUserID:(NSString *)appUserID {
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

- (void)sendCachedPurchaserInfoIfAvailable {
    RCPurchaserInfo *infoFromCache = [self readPurchaserInfoFromCacheForAppUserID:nil];
    if (infoFromCache) {
        [self sendUpdatedPurchaserInfoToDelegateIfChanged:infoFromCache];
    }
}

- (void)invalidatePurchaserInfoCacheForAppUserID:(NSString *)appUserID {
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
                                                  [self sendUpdatedPurchaserInfoToDelegateIfChanged:info];
                                              } else {
                                                  [self.deviceCache clearPurchaserInfoCacheTimestampForAppUserID:appUserID];
                                              }

                                              [self.operationDispatcher dispatchOnMainThread: ^{
                                                  completion(info, error);
                                              }];
                                          }];
    }];
}

- (void)sendUpdatedPurchaserInfoToDelegateIfChanged:(RCPurchaserInfo *)info {

    if ([self.delegate respondsToSelector:@selector(purchases:didReceiveUpdatedPurchaserInfo:)]) {
        @synchronized (self) {
            if (![self.lastSentPurchaserInfo isEqual:info]) {
                if (self.lastSentPurchaserInfo) {
                    RCDebugLog(@"%@", RCStrings.purchaserInfo.sending_updated_purchaserinfo_to_delegate);
                } else {
                    RCDebugLog(@"%@", RCStrings.purchaserInfo.sending_latest_purchaserinfo_to_delegate);
                }
                self.lastSentPurchaserInfo = info;
                [self.operationDispatcher dispatchOnMainThread:^{
                    [self.delegate purchases:self didReceiveUpdatedPurchaserInfo:info];
                }];
            }
        }
    }
}

- (void)purchaserInfoWithAppUserID:(NSString *)appUserID
                   completionBlock:(RCReceivePurchaserInfoBlock)completion {
    [self.systemInfo isApplicationBackgroundedWithCompletion:^(BOOL isAppBackgrounded) {
        RCPurchaserInfo *infoFromCache = [self readPurchaserInfoFromCacheForAppUserID:nil];
        if (infoFromCache) {
            RCDebugLog(@"%@", RCStrings.purchaserInfo.vending_cache);
            [self.operationDispatcher dispatchOnMainThread: ^{
                completion(infoFromCache, nil);
            }];
            if ([self.deviceCache isPurchaserInfoCacheStaleForAppUserID:appUserID
                                                      isAppBackgrounded:isAppBackgrounded]) {
                RCDebugLog(@"%@",
                           isAppBackgrounded
                           ? RCStrings.purchaserInfo.purchaserinfo_stale_updating_in_background
                           : RCStrings.purchaserInfo.purchaserinfo_stale_updating_in_foreground);
                [self fetchAndCachePurchaserInfoWithAppUserID:nil isAppBackgrounded:isAppBackgrounded completion:nil];
                RCSuccessLog(@"%@", RCStrings.purchaserInfo.purchaserinfo_updated_from_network);
            }
        } else {
            RCDebugLog(@"%@", RCStrings.purchaserInfo.no_cached_purchaserinfo);
            [self fetchAndCachePurchaserInfoWithAppUserID:nil
                                        isAppBackgrounded:isAppBackgrounded
                                               completion:completion];
        }
    }];
}

@end


NS_ASSUME_NONNULL_END