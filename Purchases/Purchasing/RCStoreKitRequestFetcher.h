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

@class SKProduct, SKProductsRequest, RCOperationDispatcher;

@interface RCProductsRequestFactory : NSObject
- (SKProductsRequest *)requestForProductIdentifiers:(NSSet<NSString *> *)identifiers;
- (SKReceiptRefreshRequest *)receiptRefreshRequest;
@end

@interface RCStoreKitRequestFetcher : NSObject <SKProductsRequestDelegate>

- (nullable instancetype)initWithRequestFactory:(RCProductsRequestFactory *)requestFactory
                            operationDispatcher:(RCOperationDispatcher *)operationDispatcher;

- (nullable instancetype)initWithOperationDispatcher:(RCOperationDispatcher *)operationDispatcher;

- (instancetype)init NS_UNAVAILABLE;

- (void)fetchProducts:(NSSet<NSString *> *)identifiers
           completion:(RCFetchProductsCompletionHandler)completion;

- (void)fetchReceiptData:(RCFetchReceiptCompletionHandler)completion;

@property (nonatomic) NSInteger requestTimeoutInSeconds;

@end

NS_ASSUME_NONNULL_END
