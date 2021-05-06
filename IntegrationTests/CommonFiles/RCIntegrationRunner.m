//
//  RCIntegrationRunner.m
//  CocoapodsIntegration
//
//  Created by Andrés Boedo on 10/27/20.
//

#import "RCIntegrationRunner.h"
@import Purchases;

NS_ASSUME_NONNULL_BEGIN

@implementation RCIntegrationRunner

- (void)start {
    [RCPurchases setDebugLogsEnabled:true];

    // Server URL for the tests. If set to empty string, we'll use the default URL.
    // Server URL for the tests. If set to empty string, we'll use the default URL.
    NSString *proxyURL = @"REVENUECAT_PROXY_URL";
    if (![proxyURL isEqualToString:@""]) {
        RCPurchases.proxyURL = [NSURL URLWithString:proxyURL];
    }

    [RCPurchases configureWithAPIKey:@"REVENUECAT_API_KEY"
                           appUserID:@"integrationTest"];
}

- (void)purchaserInfoWithCompletionBlock:(RCReceivePurchaserInfoBlock)completion
NS_SWIFT_NAME(purchaserInfo(_:)) {
    [RCPurchases.sharedPurchases purchaserInfoWithCompletionBlock:completion];
}

@end

NS_ASSUME_NONNULL_END
