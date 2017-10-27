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

- (NSError *)purchaserParsingError
{
    return [NSError errorWithDomain:RCBackendErrorDomain
                               code:RCErrorParsingPurchaserInfo
                           userInfo:@{
                                      NSLocalizedDescriptionKey: @"Error parsing purchaser info."
                                      }];
}

- (NSError *)errorWithBackendMessage:(NSString *)message
{
    return [NSError errorWithDomain:RCBackendErrorDomain
                               code:RCBackendError
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

- (void)handle:(BOOL)success
  withResponse:(NSDictionary * _Nullable)response
    completion:(RCBackendResponseHandler)completion
{
    RCPurchaserInfo *info = nil;

    if (success) {
        info = [[RCPurchaserInfo alloc] initWithData:response];
    }

    if (success && info) {
        completion(info, nil);
    } else if (success && (info == nil)) {
        completion(nil, [self purchaserParsingError]);
    } else if (response[@"message"]) {
        completion(nil, [self errorWithBackendMessage:response[@"message"]]);
    } else {
        completion(nil, [self unexpectedResponseError]);
    }

}

- (void)postReceiptData:(NSData *)data
              appUserID:(NSString *)appUserID
             completion:(RCBackendResponseHandler)completion
{
    // TODO: This can be nil, handle that case
    NSString *fetchToken = [data base64EncodedStringWithOptions:0];
    NSDictionary *body = @{
                               @"fetch_token": fetchToken,
                               @"app_user_id": appUserID
                           };

    [self.httpClient performRequest:@"POST"
                               path:@"/receipts"
                               body:body
                            headers:self.headers
                  completionHandler:^(BOOL success, NSDictionary * _Nullable response) {
                      [self handle:success withResponse:response completion:completion];
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
                  completionHandler:^(BOOL success, NSDictionary * _Nullable response) {
                      [self handle:success withResponse:response completion:completion];
                  }];
}

@end
