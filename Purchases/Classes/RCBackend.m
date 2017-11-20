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

NSErrorDomain const RCBackendErrorDomain = @"RCBackendErrorDomain";

@interface RCBackend ()

@property (nonatomic) RCHTTPClient *httpClient;
@property (nonatomic) NSString *APIKey;

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
      productIdentifier:(NSString *)productIdentifier
                  price:(NSDecimalNumber *)price
      introductoryPrice:(NSDecimalNumber *)introductoryPrice
           currencyCode:(NSString *)currencyCode
             completion:(RCBackendResponseHandler)completion
{
    NSString *fetchToken = [data base64EncodedStringWithOptions:0];
    NSMutableDictionary *body = [NSMutableDictionary dictionaryWithDictionary:
                                 @{
                                   @"fetch_token": fetchToken,
                                   @"app_user_id": appUserID
                                   }];

    if (productIdentifier &&
        price &&
        currencyCode) {
        [body addEntriesFromDictionary:@{
                                         @"product_id": productIdentifier,
                                         @"price": price,
                                         @"currency": currencyCode
                                         }];
    }

    [self.httpClient performRequest:@"POST"
                               path:@"/receipts"
                               body:body
                            headers:self.headers
                  completionHandler:^(NSInteger status, NSDictionary *response, NSError *error) {
                      [self handle:status withResponse:response error:error completion:completion];
                  }];
}

- (void)getSubscriberDataWithAppUserID:(NSString *)appUserID
                            completion:(RCBackendResponseHandler)completion
{
    NSString *path = [NSString stringWithFormat:@"/subscribers/%@", appUserID];

    [self.httpClient performRequest:@"GET"
                               path:path
                               body:nil
                            headers:self.headers
                  completionHandler:^(NSInteger status, NSDictionary *response, NSError *error) {
                      [self handle:status withResponse:response error:error completion:completion];
                  }];
}

@end
