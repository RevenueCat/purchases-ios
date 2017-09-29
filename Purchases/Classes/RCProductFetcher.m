//
//  RCProductFetcher.m
//  Purchases
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2017 RevenueCat, Inc. All rights reserved.
//

#import "RCProductFetcher.h"

#import <StoreKit/StoreKit.h>

#import "RCUtils.h"

@implementation RCProductsRequestFactory : NSObject
- (SKProductsRequest *)requestForProductIdentifiers:(NSSet<NSString *> * _Nonnull)identifiers
{
    return [[SKProductsRequest alloc] initWithProductIdentifiers:identifiers];
}
@end

@interface RCProductFetcher ()
@property (nonatomic) RCProductsRequestFactory *requestFactory;

@property (nonatomic) NSMutableArray<SKProductsRequest *> *productRequests;
@property (nonatomic) NSMutableArray<RCProductFetcherCompletionHandler> *completionHandlers;

@end

@implementation RCProductFetcher

- (instancetype _Nullable)init {
    return [self initWithRequestFactory:[RCProductsRequestFactory new]];
}

- (instancetype _Nullable)initWithRequestFactory:(RCProductsRequestFactory * _Nonnull)requestFactory;
{
    if (self = [super init])
    {
        self.requestFactory = requestFactory;
        self.productRequests = [NSMutableArray new];
        self.completionHandlers = [NSMutableArray new];
    }
    return self;
}

- (void)fetchProducts:(NSSet<NSString *> * _Nonnull)identifiers
           completion:(RCProductFetcherCompletionHandler)completion;
{
    SKProductsRequest *request = [self.requestFactory requestForProductIdentifiers:identifiers];
    request.delegate = self;
    [request start];

    @synchronized(self) {
        [self.productRequests addObject:request];
        [self.completionHandlers addObject:[completion copy]];
    }

    NSAssert(self.productRequests.count == self.completionHandlers.count, @"Corrupted handler storage");
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    RCProductFetcherCompletionHandler handler;
    @synchronized(self) {
        NSUInteger index = [self.productRequests indexOfObject:request];
        handler = [self.completionHandlers objectAtIndex:index];

        [self.productRequests removeObjectAtIndex:index];
        [self.completionHandlers removeObjectAtIndex:index];
    }

    handler(response.products);

    NSAssert(self.productRequests.count == self.completionHandlers.count, @"Corrupted handler storage");
}


@end
