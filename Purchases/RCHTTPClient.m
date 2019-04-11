//
//  RCHTTPClient.m
//  Purchases
//
//  Created by Jacob Eiting on 9/28/17.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//

#import "RCHTTPClient.h"
#import "RCUtils.h"
#import "RCPurchases.h"
#import "RCCrossPlatformSupport.h"

static NSString *overrideHostName = nil;

void RCOverrideServerHost(NSString *hostname)
{
    overrideHostName = hostname;
}

@interface RCHTTPClient ()

@property (nonatomic) NSURLSession *session;

@end

@implementation RCHTTPClient

+ (NSString *)serverHostName
{
    return  (overrideHostName) ? overrideHostName : @"https://api.revenuecat.com";
}

- (instancetype)init
{
    if (self = [super init]) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.HTTPMaximumConnectionsPerHost = 1;
        self.session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

+ (NSString *)systemVersion {
    NSProcessInfo *info = [[NSProcessInfo alloc] init];
    return info.operatingSystemVersionString;
}

- (void)performRequest:(NSString * _Nonnull)HTTPMethod
                  path:(NSString * _Nonnull)path
                  body:(NSDictionary * _Nullable)requestBody
               headers:(NSDictionary<NSString *, NSString *> * _Nullable)headers
     completionHandler:(RCHTTPClientResponseHandler _Nullable)completionHandler
{
    NSParameterAssert(!([HTTPMethod isEqualToString:@"GET"] && requestBody));
    NSParameterAssert(([HTTPMethod isEqualToString:@"GET"] || [HTTPMethod isEqualToString:@"POST"]));

    NSString *urlString = [NSString stringWithFormat:@"%@/v1%@", self.class.serverHostName, path];
    NSLog(@"urlString %@", urlString);

    NSMutableDictionary *defaultHeaders = [NSMutableDictionary
                                           dictionaryWithDictionary:@{@"content-type": @"application/json",
                                                                      @"X-Version": [RCPurchases frameworkVersion],
                                                                      @"X-Platform": PLATFORM_HEADER,
                                                                      @"X-Platform-Version": [self.class systemVersion]
                                                                      }];
    [defaultHeaders addEntriesFromDictionary:headers];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];

    request.HTTPMethod = HTTPMethod;
    request.allHTTPHeaderFields = defaultHeaders;

    if ([HTTPMethod isEqualToString:@"POST"]) {
        NSError *JSONParseError;
        NSData *body = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:&JSONParseError];
        if (JSONParseError) {
            RCLog(@"Error creating request JSON: %@", requestBody);
        }
        request.HTTPBody = body;
    }

    typedef void (^SessionCompletionBlock)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable);

    SessionCompletionBlock block = ^void(NSData * _Nullable data,
                                         NSURLResponse * _Nullable response,
                                         NSError * _Nullable error)
    {


        NSInteger statusCode = 599;
        NSDictionary *responseObject = nil;

        if (error == nil) {
            statusCode = ((NSHTTPURLResponse *)response).statusCode;

            RCDebugLog(@"%@ %@ %d", request.HTTPMethod, request.URL.path, statusCode);

            NSError *jsonError;
            responseObject = [NSJSONSerialization JSONObjectWithData:data
                                                             options:0
                                                               error:&jsonError];
            
            if (jsonError) {
                RCLog(@"Error parsing JSON %@", jsonError.localizedDescription);
                RCLog(@"Data received: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                error = jsonError;
            }
        }

        if (completionHandler != nil) {
            completionHandler(statusCode, responseObject, error);
        }
    };

    RCDebugLog(@"%@ %@", request.HTTPMethod, request.URL.path);

    NSURLSessionTask *task = [self.session dataTaskWithRequest:request
                                             completionHandler:block];
    [task resume];
}


@end
