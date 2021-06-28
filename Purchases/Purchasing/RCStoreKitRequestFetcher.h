//
//  RCProductFetcher.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^RCFetchProductsCompletionHandler)(NSArray<SKProduct *> *products);

typedef void(^RCFetchReceiptCompletionHandler)(void);

@interface RCReceiptRefreshRequestFactory : NSObject
- (SKReceiptRefreshRequest *)receiptRefreshRequest;
@end

@interface RCStoreKitRequestFetcher : NSObject

- (nullable instancetype)initWithRequestFactory:(RCReceiptRefreshRequestFactory *)requestFactory;
- (void)fetchReceiptData:(RCFetchReceiptCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
