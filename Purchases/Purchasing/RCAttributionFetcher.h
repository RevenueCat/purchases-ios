//
//  RCAttributionFetcher.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "RCAttributionNetwork.h"

NS_ASSUME_NONNULL_BEGIN

@class RCDeviceCache, RCIdentityManager;

typedef void (^RCAttributionDetailsBlock)(NSDictionary<NSString *, NSObject *> *_Nullable, NSError *_Nullable);

@interface RCAttributionFetcher : NSObject

- (instancetype)initWithDeviceCache:(RCDeviceCache *)deviceCache
                    identityManager:(RCIdentityManager *)identityManager NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (nullable NSString *)identifierForAdvertisers;

- (nullable NSString *)identifierForVendor;

- (void)adClientAttributionDetailsWithCompletionBlock:(RCAttributionDetailsBlock)completionHandler;

- (NSString *)latestNetworkIdAndAdvertisingIdentifierSentForNetwork:(RCAttributionNetwork)network;

@end

NS_ASSUME_NONNULL_END
