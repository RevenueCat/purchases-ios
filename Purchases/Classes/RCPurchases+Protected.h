//
//  RCPurchases+Protected.h
//  Purchases
//
//  Created by Jacob Eiting on 10/2/17.
//  Copyright © 2017 RevenueCat, Inc. All rights reserved.
//

#import <Purchases/Purchases.h>

@class RCStoreKitRequestFetcher, RCBackend, RCStoreKitWrapper;

NS_ASSUME_NONNULL_BEGIN

@interface RCPurchases (Protected)

- (instancetype _Nullable)initWithAppUserID:(NSString * _Nullable)appUserID
                             requestFetcher:(RCStoreKitRequestFetcher *)requestFetcher
                                    backend:(RCBackend *)backend
                            storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
                         notificationCenter:(NSNotificationCenter *)notificationCenter
                               userDefaults:(NSUserDefaults *)userDefaults;

@end

NS_ASSUME_NONNULL_END
