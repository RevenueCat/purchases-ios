//
//  RCInstallationRunner.m
//  CocoapodsInstallation
//
//  Created by Andrés Boedo on 10/27/20.
//

#import "RCInstallationRunner.h"
@import RevenueCat;

NS_ASSUME_NONNULL_BEGIN

@implementation RCInstallationRunner

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

- (void)getCustomerInfoWithCompletion:(void (^)(RCCustomerInfo * _Nullable, NSError * _Nullable))completion {
    [RCPurchases.sharedPurchases getCustomerInfoWithCompletion:completion];
}

@end

NS_ASSUME_NONNULL_END
