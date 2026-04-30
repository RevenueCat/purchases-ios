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
        RCCustomPaywallImpressionParams *paramsWithOffering __unused = [[RCCustomPaywallImpressionParams alloc] initWithPaywallId:@"my-paywall" offeringId:@"my-offering"];
        RCCustomPaywallImpressionParams *paramsOfferingOnly __unused = [[RCCustomPaywallImpressionParams alloc] initWithPaywallId:nil offeringId:@"my-offering"];
        RCCustomPaywallImpressionParams *paramsBothNil __unused = [[RCCustomPaywallImpressionParams alloc] initWithPaywallId:nil offeringId:nil];
        RCCustomPaywallImpressionParams *paramsIdNilOffering __unused = [[RCCustomPaywallImpressionParams alloc] initWithPaywallId:@"my-paywall" offeringId:nil];

        RCOffering *offering = [[RCOffering alloc] initWithIdentifier:@"my-offering"
                                                    serverDescription:@""
                                                             metadata:@{}
                                                    availablePackages:@[]
                                                       webCheckoutUrl:nil];
        RCCustomPaywallImpressionParams *paramsWithOfferingObject __unused = [[RCCustomPaywallImpressionParams alloc] initWithPaywallId:@"my-paywall" offering:offering];
        RCCustomPaywallImpressionParams *paramsWithOfferingObjectNilPaywall __unused = [[RCCustomPaywallImpressionParams alloc] initWithPaywallId:nil offering:offering];

        // CustomPaywallImpressionParams properties
        NSString *paywallId __unused = paramsWithId.paywallId;
        NSString *offeringId __unused = paramsWithOffering.offeringId;
        RCOffering *offeringObject __unused = paramsWithOfferingObject.offering;

        // trackCustomPaywallImpression API
        RCPurchases *purchases = RCPurchases.sharedPurchases;
        [purchases trackCustomPaywallImpression:paramsDefault];
        [purchases trackCustomPaywallImpression:paramsWithId];
        [purchases trackCustomPaywallImpression:paramsWithOfferingObject];
        [purchases trackCustomPaywallImpression];
    }
}

@end
