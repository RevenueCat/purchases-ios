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
    if (RCPurchases.isConfigured) {
        return;
    }

    RCPurchases.logLevel = RCLogLevelVerbose;

    // Server URL for the tests. If set to empty string, we'll use the default URL.
    NSString *proxyURL = @"REVENUECAT_PROXY_URL";
    if (![proxyURL isEqualToString:@""]) {
        RCPurchases.proxyURL = [NSURL URLWithString:proxyURL];
    }

    [RCPurchases configureWithConfiguration:[[[RCConfiguration builderWithAPIKey:@"REVENUECAT_API_KEY"]
                                              withAppUserID:@"integrationTest"]
                                             build]];
}

- (void)getCustomerInfoWithCompletion:(void (^)(RCCustomerInfo * _Nullable, NSError * _Nullable))completion {
    [RCPurchases.sharedPurchases getCustomerInfoWithCompletion:completion];
}

@end

NS_ASSUME_NONNULL_END
