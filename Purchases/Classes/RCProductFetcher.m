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

@property (nonatomic) NSMutableArray<SKRequest *> *requests;
@property (nonatomic) NSMutableArray *completionHandlers;

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
        self.requests = [NSMutableArray new];
        self.completionHandlers = [NSMutableArray new];
    }
    return self;
}

- (void)startRequest:(SKRequest *)request completion:(id)completion {
    request.delegate = self;

    @synchronized(self) {
        [self.requests addObject:request];
        [self.completionHandlers addObject:completion];
    }

    [request start];

    NSAssert(self.requests.count == self.completionHandlers.count, @"Corrupted handler storage");
}

- (void)fetchProducts:(NSSet<NSString *> * _Nonnull)identifiers
           completion:(RCProductFetcherCompletionHandler)completion;
{
    SKProductsRequest *request = [self.requestFactory requestForProductIdentifiers:identifiers];
    [self startRequest:request completion:[completion copy]];
}

- (void)fetchReceiptData:(void (^ _Nonnull)(void))completion
{
    SKReceiptRefreshRequest *request = [self.requestFactory receiptRefreshRequest];
    [self startRequest:request completion:[completion copy]];
}

- (id)finishRequest:(SKRequest *)request {
    id handler = nil;
    @synchronized(self) {
        NSUInteger index = [self.requests indexOfObject:request];
        handler = [self.completionHandlers objectAtIndex:index];
        [self.requests removeObjectAtIndex:index];
        [self.completionHandlers removeObjectAtIndex:index];
    }
    NSAssert(self.requests.count == self.completionHandlers.count, @"Corrupted handler storage");
    return handler;
}

- (void)requestDidFinish:(SKRequest *)request
{
    void (^handler)(void)  = [self finishRequest:request];
    handler();
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    RCProductFetcherCompletionHandler handler = [self finishRequest:request];
    handler(response.products);
}

@end
