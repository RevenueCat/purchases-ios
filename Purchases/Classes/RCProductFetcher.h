//
//  RCProductFetcher.h
//  Purchases
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2017 RevenueCat, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef void(^RCProductFetcherCompletionHandler)(NSArray<SKProduct *> * _Nonnull products);

@class SKProduct, SKProductsRequest;

@interface RCProductsRequestFactory : NSObject
- (SKProductsRequest * _Nonnull)requestForProductIdentifiers:(NSSet<NSString *> * _Nonnull)identifiers;
@end

@interface RCProductFetcher : NSObject <SKProductsRequestDelegate>

- (instancetype _Nullable)initWithRequestFactory:(RCProductsRequestFactory * _Nonnull)requestFactory;

- (void)fetchProducts:(NSSet<NSString *> * _Nonnull)identifiers
           completion:(RCProductFetcherCompletionHandler _Nonnull)completion;

@end
