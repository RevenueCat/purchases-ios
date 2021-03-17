//
// Created by Andrés Boedo on 1/4/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class RCPurchaserInfo, RCDeviceCache, RCBackend, RCOperationDispatcher, RCSystemInfo;
typedef void (^RCReceivePurchaserInfoBlock)(RCPurchaserInfo * _Nullable, NSError * _Nullable) NS_SWIFT_NAME(Purchases.ReceivePurchaserInfoBlock);

NS_SWIFT_NAME(PurchaserInfoManagerDelegate)
@protocol RCPurchaserInfoManagerDelegate <NSObject>
- (void)purchaserInfoManagerDidReceiveUpdatedPurchaserInfo:(RCPurchaserInfo *)purchaserInfo;
@end

NS_SWIFT_NAME(PurchaserInfoManager)
@interface RCPurchaserInfoManager : NSObject

@property (nonatomic, weak, nullable) id<RCPurchaserInfoManagerDelegate> delegate;

- (instancetype)initWithOperationDispatcher:(RCOperationDispatcher *)operationDispatcher
                                deviceCache:(RCDeviceCache *)deviceCache
                                    backend:(RCBackend *)backend
                                 systemInfo:(RCSystemInfo *)systemInfo;

- (void)fetchAndCachePurchaserInfoWithAppUserID:(NSString *)appUserID
                              isAppBackgrounded:(BOOL)isAppBackgrounded
                                     completion:(nullable RCReceivePurchaserInfoBlock)completion;

- (void)fetchAndCachePurchaserInfoIfStaleWithAppUserID:(NSString *)appUserID
                                     isAppBackgrounded:(BOOL)isAppBackgrounded
                                            completion:(nullable RCReceivePurchaserInfoBlock)completion;
- (void)sendCachedPurchaserInfoIfAvailableForAppUserID:(NSString *)appUserID;

- (void)purchaserInfoWithAppUserID:(NSString *)appUserID
                   completionBlock:(nullable RCReceivePurchaserInfoBlock)completion;

- (nullable RCPurchaserInfo *)cachedPurchaserInfoForAppUserID:(NSString *)appUserID;
- (void)cachePurchaserInfo:(RCPurchaserInfo *)info forAppUserID:(NSString *)appUserID;
- (void)clearPurchaserInfoCacheForAppUserID:(NSString *)appUserID;

@end


NS_ASSUME_NONNULL_END
