//
//  RCProductFetcher.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef void(^RCFetchProductsCompletionHandler)(NSArray<SKProduct *> * _Nonnull products);
typedef void(^RCFetchReceiptCompletionHandler)(void);

@class SKProduct, SKProductsRequest;

@interface RCProductsRequestFactory : NSObject
- (SKProductsRequest * _Nonnull)requestForProductIdentifiers:(NSSet<NSString *> * _Nonnull)identifiers;
- (SKReceiptRefreshRequest * _Nonnull)receiptRefreshRequest;
@end

@interface RCStoreKitRequestFetcher : NSObject <SKProductsRequestDelegate>

- (instancetype _Nullable)initWithRequestFactory:(RCProductsRequestFactory * _Nonnull)requestFactory;

- (void)fetchProducts:(NSSet<NSString *> * _Nonnull)identifiers
           completion:(RCFetchProductsCompletionHandler _Nonnull)completion;

- (void)fetchReceiptData:(RCFetchReceiptCompletionHandler _Nonnull)completion;

@end
