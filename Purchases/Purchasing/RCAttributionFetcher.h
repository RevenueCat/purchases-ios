//
//  RCAttributionFetcher.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^RCAttributionDetailsBlock)(NSDictionary<NSString *, NSObject *> *_Nullable, NSError *_Nullable);

@interface RCAttributionFetcher : NSObject

- (nullable NSString *)identifierForAdvertisers;

- (nullable NSString *)identifierForVendor;

- (void)adClientAttributionDetailsWithCompletionBlock:(RCAttributionDetailsBlock)completionHandler;

@end

NS_ASSUME_NONNULL_END
