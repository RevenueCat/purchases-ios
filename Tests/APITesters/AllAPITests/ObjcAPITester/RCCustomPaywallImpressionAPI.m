//
//  RCCustomPaywallImpressionAPI.m
//  ObjCAPITester
//

#import "RCCustomPaywallImpressionAPI.h"

@import RevenueCat;

@implementation RCCustomPaywallImpressionAPI

+ (void)checkAPI {
    if (@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)) {
        // CustomPaywallImpressionParams API
        RCCustomPaywallImpressionParams *paramsDefault __unused = [[RCCustomPaywallImpressionParams alloc] initWithPaywallId:nil];
        RCCustomPaywallImpressionParams *paramsWithId __unused = [[RCCustomPaywallImpressionParams alloc] initWithPaywallId:@"my-paywall"];
        RCCustomPaywallImpressionParams *paramsWithNil __unused = [[RCCustomPaywallImpressionParams alloc] initWithPaywallId:nil];

        // CustomPaywallImpressionParams properties
        NSString *paywallId __unused = paramsWithId.paywallId;

        // trackCustomPaywallImpression API
        RCPurchases *purchases = RCPurchases.sharedPurchases;
        [purchases trackCustomPaywallImpression:paramsDefault];
        [purchases trackCustomPaywallImpression:paramsWithId];
        [purchases trackCustomPaywallImpression];
    }
}

@end
