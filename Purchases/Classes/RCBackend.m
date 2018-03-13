//
//  RCBackend.m
//  Purchases
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2017 RevenueCat, Inc. All rights reserved.
//

#import "RCBackend.h"

#import "RCHTTPClient.h"
#import "RCPurchaserInfo+Protected.h"
#import "RCIntroEligibility.h"

NSErrorDomain const RCBackendErrorDomain = @"RCBackendErrorDomain";

RCPaymentMode RCPaymentModeFromSKProductDiscountPaymentMode(SKProductDiscountPaymentMode paymentMode)
{
    switch (paymentMode) {
        case SKProductDiscountPaymentModePayUpFront:
            return RCPaymentModePayUpFront;
        case SKProductDiscountPaymentModePayAsYouGo:
            return RCPaymentModePayAsYouGo;
        case SKProductDiscountPaymentModeFreeTrial:
            return RCPaymentModeFreeTrial;
        default:
            return RCPaymentModeNone;
    }
}

@interface RCBackend ()

@property (nonatomic) RCHTTPClient *httpClient;
@property (nonatomic) NSString *APIKey;

@property (nonatomic) NSMutableDictionary<NSString *, NSMutableArray *> *receiptCallbacksCache;

@end

@implementation RCBackend

- (instancetype _Nullable)initWithAPIKey:(NSString *)APIKey
{
    RCHTTPClient *client = [[RCHTTPClient alloc] init];
    return [self initWithHTTPClient:client
                             APIKey:APIKey];
}

- (instancetype _Nullable)initWithHTTPClient:(RCHTTPClient *)client
                                      APIKey:(NSString *)APIKey
{
    if (self = [super init]) {
        self.httpClient = client;
        self.APIKey = APIKey;

        self.receiptCallbacksCache = [NSMutableDictionary new];
    }
    return self;
}

- (NSDictionary<NSString *, NSString *> *)headers
{
    return @{
             @"Authorization":
                 [NSString stringWithFormat:@"Basic %@", self.APIKey]
             };
}

- (NSError *)errorWithBackendMessage:(NSString *)message finishable:(BOOL)finishable
{
    return [NSError errorWithDomain:RCBackendErrorDomain
                               code:(finishable ? RCFinishableError : RCUnfinishableError)
                           userInfo:@{
                                      NSLocalizedDescriptionKey: message
                                      }];
}

- (NSError *)unexpectedResponseError
{
    return [NSError errorWithDomain:RCBackendErrorDomain
                               code:RCUnexpectedBackendResponse
                           userInfo:@{
                                      NSLocalizedDescriptionKey: @"Received malformed response from the backend."
                                      }];
}

- (void)handle:(NSInteger)statusCode
  withResponse:(NSDictionary * _Nullable)response
         error:(NSError * _Nullable)error
    completion:(RCBackendResponseHandler)completion
{

    RCPurchaserInfo *info = nil;
    NSError *responseError = nil;

    if (statusCode < 300) {
        info = [[RCPurchaserInfo alloc] initWithData:response];
        if (info == nil) {
            responseError = [self unexpectedResponseError];
        }
    } else {
        BOOL finishable = (statusCode < 500);
        NSString *message = response[@"message"] ?: @"Unknown backend error.";
        responseError = [self errorWithBackendMessage:message finishable:finishable];
    }

    completion(info, responseError);
}


- (void)postReceiptData:(NSData *)data
              appUserID:(NSString *)appUserID
              isRestore:(BOOL)isRestore
      productIdentifier:(NSString *)productIdentifier
                  price:(NSDecimalNumber *)price
            paymentMode:(RCPaymentMode)paymentMode
      introductoryPrice:(NSDecimalNumber *)introductoryPrice
           currencyCode:(NSString *)currencyCode
             completion:(RCBackendResponseHandler)completion
{
    NSString *fetchToken = [data base64EncodedStringWithOptions:0];
    NSMutableDictionary *body = [NSMutableDictionary dictionaryWithDictionary:
                                 @{
                                   @"fetch_token": fetchToken,
                                   @"app_user_id": appUserID,
                                   @"is_restore": @(isRestore)
                                   }];

    NSString *cacheKey = [NSString stringWithFormat:@"%@-%@", @(isRestore), fetchToken];
    @synchronized(self) {
        NSMutableArray *callbacks = [self.receiptCallbacksCache objectForKey:cacheKey];
        BOOL cacheMiss = callbacks == nil;

        if (cacheMiss) {
            callbacks = [NSMutableArray new];
            self.receiptCallbacksCache[cacheKey] = callbacks;
        }

        [callbacks addObject:[completion copy]];

        if (!cacheMiss) return;
    }

    if (productIdentifier &&
        price &&
        currencyCode) {
        [body addEntriesFromDictionary:@{
                                         @"product_id": productIdentifier,
                                         @"price": price,
                                         @"currency": currencyCode
                                         }];

        if (paymentMode != RCPaymentModeNone) {
            [body addEntriesFromDictionary:@{
                                             @"payment_mode": @((NSUInteger)paymentMode),
                                             @"introductory_price": introductoryPrice
                                             }];
        }
    }

    [self.httpClient performRequest:@"POST"
                               path:@"/receipts"
                               body:body
                            headers:self.headers
                  completionHandler:^(NSInteger status, NSDictionary *response, NSError *error) {
                      @synchronized(self) {
                          NSMutableArray *callbacks = self.receiptCallbacksCache[cacheKey];
                          NSParameterAssert(callbacks);

                          for (RCBackendResponseHandler callback in callbacks) {
                              [self handle:status withResponse:response error:error completion:callback];
                          }

                          self.receiptCallbacksCache[cacheKey] = nil;
                      }
                  }];
}

- (void)getSubscriberDataWithAppUserID:(NSString *)appUserID
                            completion:(RCBackendResponseHandler)completion
{
    NSString *escapedAppUserID = [appUserID stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    NSString *path = [NSString stringWithFormat:@"/subscribers/%@", escapedAppUserID];

    [self.httpClient performRequest:@"GET"
                               path:path
                               body:nil
                            headers:self.headers
                  completionHandler:^(NSInteger status, NSDictionary *response, NSError *error) {
                      [self handle:status withResponse:response error:error completion:completion];
                  }];
}

- (void)getIntroElgibilityForAppUserID:(NSString *)appUserID
                           receiptData:(NSData *)receiptData
                    productIdentifiers:(NSArray<NSString *> *)productIdentifiers
                            completion:(RCIntroEligibilityResponseHandler)completion
{
    if (productIdentifiers.count == 0) {
        completion(@{});
        return;
    }

    NSString *fetchToken = [receiptData base64EncodedStringWithOptions:0];

    NSString *escapedAppUserID = [appUserID stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    NSString *path = [NSString stringWithFormat:@"/subscribers/%@/intro_eligibility", escapedAppUserID];
    [self.httpClient performRequest:@"POST"
                               path:path
                               body:@{
                                      @"product_identifiers": productIdentifiers,
                                      @"fetch_token": fetchToken
                                      }
                            headers:self.headers
                  completionHandler:^(NSInteger statusCode, NSDictionary * _Nullable response, NSError * _Nullable error) {
                      if (statusCode >= 300) {
                          response = @{};
                      }

                      NSMutableDictionary *eligibilties = [NSMutableDictionary new];
                      for (NSString *productID in productIdentifiers) {
                          NSNumber *e = response[productID];
                          RCIntroEligibityStatus status;
                          if (e == nil || [e isKindOfClass:[NSNull class]]) {
                              status = RCIntroEligibityStatusUnknown;
                          } else if ([e boolValue]) {
                              status = RCIntroEligibityStatusEligible;
                          } else {
                              status = RCIntroEligibityStatusIneligible;
                          }

                          eligibilties[productID] = [[RCIntroEligibility alloc] initWithEligibilityStatus:status];
                      }

                      completion([NSDictionary dictionaryWithDictionary:eligibilties]);
    }];
}

@end
