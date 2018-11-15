//
//  RCProductFetcher.m
//  Purchases
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2018 RevenueCat, Inc. All rights reserved.
//

#import "RCStoreKitRequestFetcher.h"

#import <StoreKit/StoreKit.h>

#import "RCUtils.h"

@implementation RCProductsRequestFactory : NSObject
- (SKProductsRequest *)requestForProductIdentifiers:(NSSet<NSString *> * _Nonnull)identifiers
{
    return [[SKProductsRequest alloc] initWithProductIdentifiers:identifiers];
}

- (SKReceiptRefreshRequest * _Nonnull)receiptRefreshRequest
{
    return [[SKReceiptRefreshRequest alloc] init];
}

@end

@interface RCStoreKitRequestFetcher ()
@property (nonatomic) RCProductsRequestFactory *requestFactory;

@property (nonatomic) NSMutableArray<SKRequest *> *productsRequests;
@property (nonatomic) NSMutableArray *productsCompletionHandlers;

@property (nonatomic) SKRequest *receiptRefreshRequest;
@property (nonatomic) NSMutableArray *receiptRefreshCompletionHandlers;

@end

@implementation RCStoreKitRequestFetcher

- (instancetype _Nullable)init {
    return [self initWithRequestFactory:[RCProductsRequestFactory new]];
}

- (instancetype _Nullable)initWithRequestFactory:(RCProductsRequestFactory * _Nonnull)requestFactory;
{
    if (self = [super init]) {
        self.requestFactory = requestFactory;
        self.productsRequests = [NSMutableArray new];
        self.productsCompletionHandlers = [NSMutableArray new];
        
        self.receiptRefreshRequest = nil;
        self.receiptRefreshCompletionHandlers = [NSMutableArray new];
    }
    return self;
}

- (void)fetchProducts:(NSSet<NSString *> * _Nonnull)identifiers
           completion:(RCFetchProductsCompletionHandler)completion;
{
    SKProductsRequest *request = [self.requestFactory requestForProductIdentifiers:identifiers];
    request.delegate = self;
    
    @synchronized(self) {
        [self.productsRequests addObject:request];
        [self.productsCompletionHandlers addObject:[completion copy]];
    }
    
    [request start];
    
    NSAssert(self.productsRequests.count == self.productsCompletionHandlers.count, @"Corrupted handler storage");
}

- (void)fetchReceiptData:(void (^ _Nonnull)(void))completion
{
    @synchronized(self) {
        [self.receiptRefreshCompletionHandlers addObject:[completion copy]];
        
        if (self.receiptRefreshRequest == nil) {
            self.receiptRefreshRequest = [self.requestFactory receiptRefreshRequest];
            self.receiptRefreshRequest.delegate = self;
            [self.receiptRefreshRequest start];
        }
    }
}

- (RCFetchProductsCompletionHandler)finishProductsRequest:(SKRequest *)request
{
    id handler = nil;
    @synchronized(self) {
        NSUInteger index = [self.productsRequests indexOfObject:request];
        handler = [self.productsCompletionHandlers objectAtIndex:index];
        [self.productsRequests removeObjectAtIndex:index];
        [self.productsCompletionHandlers removeObjectAtIndex:index];
    }
    NSAssert(self.productsRequests.count == self.productsCompletionHandlers.count, @"Corrupted handler storage");
    return handler;
}

- (NSArray<RCFetchReceiptCompletionHandler> *)finishReceiptRequest:(SKRequest *)request
{
    @synchronized(self) {
        self.receiptRefreshRequest = nil;
        NSArray *handlers = [NSArray arrayWithArray:self.receiptRefreshCompletionHandlers];
        self.receiptRefreshCompletionHandlers = [NSMutableArray new];
        return handlers;
    }
}

- (void)requestDidFinish:(SKRequest *)request
{
    if ([request isKindOfClass:SKReceiptRefreshRequest.class]) {
        NSArray<RCFetchReceiptCompletionHandler> *receiptHandlers = [self finishReceiptRequest:request];
        for (RCFetchReceiptCompletionHandler receiptHandler in receiptHandlers) {
            receiptHandler();
        }
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    RCDebugLog(@"SKRequest failed: %@", error.localizedDescription);
    if ([request isKindOfClass:SKReceiptRefreshRequest.class]) {
        NSArray<RCFetchReceiptCompletionHandler> *receiptHandlers = [self finishReceiptRequest:request];
        for (RCFetchReceiptCompletionHandler receiptHandler in receiptHandlers) {
            receiptHandler();
        }
    } else if ([request isKindOfClass:SKProductsRequest.class]) {
        RCFetchProductsCompletionHandler productsHandler = [self finishProductsRequest:request];
        productsHandler(@[]);
    }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    RCFetchProductsCompletionHandler handler = [self finishProductsRequest:request];
    handler(response.products);
}

@end
