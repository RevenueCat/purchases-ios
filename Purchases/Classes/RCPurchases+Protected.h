//
//  RCPurchases+Protected.h
//  Purchases
//
//  Created by Jacob Eiting on 10/2/17.
//  Copyright © 2017 RevenueCat, Inc. All rights reserved.
//

#import <Purchases/Purchases.h>

@class RCProductFetcher, RCBackend, RCStoreKitWrapper;

NS_ASSUME_NONNULL_BEGIN

@interface RCPurchases (Protected)

- (instancetype _Nullable)initWithSharedSecret:(NSString *)sharedSecret
                                     appUserID:(NSString *)appUserID
                                productFetcher:(RCProductFetcher *)productFetcher
                                       backend:(RCBackend *)backend
                               storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper;

@end

NS_ASSUME_NONNULL_END
