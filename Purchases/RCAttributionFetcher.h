//
//  RCAttributionFetcher.h
//  Purchases
//
//  Created by César de la Vega  on 4/17/19.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCAttributionFetcher : NSObject

- (nullable NSString *)advertisingIdentifier;

- (nullable NSString *)identifierForVendor;

- (void)adClientAttributionDetailsWithCompletionBlock:(void (^)(NSDictionary<NSString *, NSObject *> * _Nullable attributionDetails, NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
