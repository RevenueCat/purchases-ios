//
//  RCProductFetcher.m
//  Purchases
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
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

@property (nonatomic) NSMutableDictionary<NSSet *, SKRequest *> *productsRequests;
@property (nonatomic) NSMutableDictionary<NSSet *, NSMutableArray<RCFetchProductsCompletionHandler> *> *productsCompletionHandlers;

@property (nonatomic) SKRequest *receiptRefreshRequest;
@property (nonatomic) NSMutableArray<RCFetchReceiptCompletionHandler> *receiptRefreshCompletionHandlers;

@end

@implementation RCStoreKitRequestFetcher

- (instancetype _Nullable)init {
    return [self initWithRequestFactory:[RCProductsRequestFactory new]];
}

- (instancetype _Nullable)initWithRequestFactory:(RCProductsRequestFactory * _Nonnull)requestFactory;
{
    if (self = [super init]) {
        self.requestFactory = requestFactory;
        self.productsRequests = [NSMutableDictionary new];
        self.productsCompletionHandlers = [NSMutableDictionary new];
        
        self.receiptRefreshRequest = nil;
        self.receiptRefreshCompletionHandlers = [NSMutableArray new];
    }
    return self;
}

- (void)fetchProducts:(NSSet<NSString *> * _Nonnull)identifiers
           completion:(RCFetchProductsCompletionHandler)completion;
{
    
    @synchronized(self) {
        SKProductsRequest *newRequest = nil;
        
        if (self.productsRequests[identifiers] == nil) {
            RCDebugLog(@"Requesting products with identifiers: %@", identifiers);
            newRequest = [self.requestFactory requestForProductIdentifiers:identifiers];
            newRequest.delegate = self;
            
            self.productsRequests[identifiers] = newRequest;
            self.productsCompletionHandlers[identifiers] = [NSMutableArray new];
        }
        
        NSMutableArray *handlers = self.productsCompletionHandlers[identifiers];
        NSAssert(handlers != nil, @"Curropted handler storage");
        
        [handlers addObject:completion];
        
        
        [newRequest start];
    }
    
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

- (NSArray<RCFetchProductsCompletionHandler> *)finishProductsRequest:(SKRequest *)request
{
    NSMutableArray<RCFetchProductsCompletionHandler> *handlers;
    @synchronized(self) {
        NSSet *associatedProductIdentifiers = nil;
        for (NSSet *productIdentifiers in self.productsRequests) {
            SKRequest *r = self.productsRequests[productIdentifiers];
            if (r == request) {
                NSAssert(associatedProductIdentifiers == nil, @"Request maps to multiple product sets");
                associatedProductIdentifiers = productIdentifiers;
            }
        }
        NSAssert(associatedProductIdentifiers != nil, @"Could not find request in storage");
        
        handlers = self.productsCompletionHandlers[associatedProductIdentifiers];
        [self.productsRequests removeObjectForKey:associatedProductIdentifiers];
        [self.productsCompletionHandlers removeObjectForKey:associatedProductIdentifiers];
    }
    NSAssert(self.productsRequests.count == self.productsCompletionHandlers.count, @"Corrupted handler storage");
    return handlers;
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
        NSArray<RCFetchProductsCompletionHandler> *productsHandlers = [self finishProductsRequest:request];
        for (RCFetchProductsCompletionHandler handler in productsHandlers)
        {
            handler(@[]);
        }
    }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    RCDebugLog(@"Products request finished");
    RCDebugLog(@"Valid Products:");
    for (SKProduct *p in response.products)
    {
        RCDebugLog(@"%@ - %@", p.productIdentifier, p);
    }
    RCDebugLog(@"Invalid Product Identifiers - %@", response.invalidProductIdentifiers);
    
    NSArray<RCFetchProductsCompletionHandler> *handlers = [self finishProductsRequest:request];
    RCDebugLog(@"%d completion handlers waiting on products", handlers.count);
    for (RCFetchProductsCompletionHandler handler in handlers)
    {
        handler(response.products);
    }
}

@end
