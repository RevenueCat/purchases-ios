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

@class SKProduct, SKProductsRequest;

@interface RCProductsRequestFactory : NSObject
- (SKProductsRequest *)requestForProductIdentifiers:(NSSet<NSString *> *)identifiers;
- (SKReceiptRefreshRequest *)receiptRefreshRequest;
@end

@interface RCStoreKitRequestFetcher : NSObject <SKProductsRequestDelegate>

- (nullable instancetype)initWithRequestFactory:(RCProductsRequestFactory *)requestFactory;

- (void)fetchProducts:(NSSet<NSString *> *)identifiers
           completion:(RCFetchProductsCompletionHandler)completion;

- (void)fetchReceiptData:(RCFetchReceiptCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
