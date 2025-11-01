//
//  RCAdTrackerAPI.m
//  ObjCAPITester
//
//  Created by RevenueCat on 1/20/25.
//

#import "RCAdTrackerAPI.h"

#ifdef ENABLE_AD_EVENTS_TRACKING

@import RevenueCat;

@implementation RCAdTrackerAPI

+ (void)checkAPI {
    if (@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)) {
        // MediatorName API
        RCMediatorName *mediatorFromRaw __unused = [[RCMediatorName alloc] initWithRawValue:@"CustomNetwork"];
        RCMediatorName *adMob __unused = RCMediatorName.adMob;
        RCMediatorName *appLovin __unused = RCMediatorName.appLovin;
        NSString *rawValue __unused = mediatorFromRaw.rawValue;

        // AdRevenue.Precision API
        RCAdRevenuePrecision *precisionFromRaw __unused = [[RCAdRevenuePrecision alloc] initWithRawValue:@"custom"];
        RCAdRevenuePrecision *exact __unused = RCAdRevenuePrecision.exact;
        RCAdRevenuePrecision *publisherDefined __unused = RCAdRevenuePrecision.publisherDefined;
        RCAdRevenuePrecision *estimated __unused = RCAdRevenuePrecision.estimated;
        RCAdRevenuePrecision *unknown __unused = RCAdRevenuePrecision.unknown;
        NSString *precisionRawValue __unused = exact.rawValue;

        // AdDisplayed API - with placement
        RCAdDisplayed *displayedWithPlacement __unused = [[RCAdDisplayed alloc] initWithNetworkName:@"AdMob"
                                                                                        mediatorName:RCMediatorName.appLovin
                                                                                           placement:@"home_screen"
                                                                                            adUnitId:@"ca-app-pub-123"
                                                                                        impressionId:@"instance-123"];

        // AdDisplayed API - without placement (convenience init)
        RCAdDisplayed *displayedNoPlacement __unused = [[RCAdDisplayed alloc] initWithNetworkName:@"AdMob"
                                                                                      mediatorName:RCMediatorName.appLovin
                                                                                          adUnitId:@"ca-app-pub-123"
                                                                                      impressionId:@"instance-123"];

        // AdDisplayed properties
        NSString *networkName __unused = displayedWithPlacement.networkName;
        RCMediatorName *mediator __unused = displayedWithPlacement.mediatorName;
        NSString *placement __unused = displayedWithPlacement.placement;
        NSString *adUnitId __unused = displayedWithPlacement.adUnitId;
        NSString *impressionId __unused = displayedWithPlacement.impressionId;

        // AdOpened API - with placement
        RCAdOpened *openedWithPlacement __unused = [[RCAdOpened alloc] initWithNetworkName:@"AdMob"
                                                                               mediatorName:RCMediatorName.appLovin
                                                                                  placement:@"home_screen"
                                                                                   adUnitId:@"ca-app-pub-123"
                                                                               impressionId:@"instance-123"];

        // AdOpened API - without placement (convenience init)
        RCAdOpened *openedNoPlacement __unused = [[RCAdOpened alloc] initWithNetworkName:@"AdMob"
                                                                             mediatorName:RCMediatorName.appLovin
                                                                                 adUnitId:@"ca-app-pub-123"
                                                                             impressionId:@"instance-123"];

        // AdOpened properties
        NSString *openedNetworkName __unused = openedWithPlacement.networkName;
        RCMediatorName *openedMediator __unused = openedWithPlacement.mediatorName;
        NSString *openedPlacement __unused = openedWithPlacement.placement;
        NSString *openedAdUnitId __unused = openedWithPlacement.adUnitId;
        NSString *openedImpressionId __unused = openedWithPlacement.impressionId;

        // AdRevenue API - with placement
        RCAdRevenue *revenueWithPlacement __unused = [[RCAdRevenue alloc] initWithNetworkName:@"AdMob"
                                                                                  mediatorName:RCMediatorName.appLovin
                                                                                     placement:@"home_screen"
                                                                                      adUnitId:@"ca-app-pub-123"
                                                                                  impressionId:@"instance-123"
                                                                                 revenueMicros:1500000
                                                                                      currency:@"USD"
                                                                                     precision:RCAdRevenuePrecision.exact];

        // AdRevenue API - without placement (convenience init)
        RCAdRevenue *revenueNoPlacement __unused = [[RCAdRevenue alloc] initWithNetworkName:@"AdMob"
                                                                               mediatorName:RCMediatorName.appLovin
                                                                                   adUnitId:@"ca-app-pub-123"
                                                                               impressionId:@"instance-123"
                                                                              revenueMicros:1500000
                                                                                   currency:@"USD"
                                                                                  precision:RCAdRevenuePrecision.exact];

        // AdRevenue properties
        NSString *revenueNetworkName __unused = revenueWithPlacement.networkName;
        RCMediatorName *revenueMediator __unused = revenueWithPlacement.mediatorName;
        NSString *revenuePlacement __unused = revenueWithPlacement.placement;
        NSString *revenueAdUnitId __unused = revenueWithPlacement.adUnitId;
        NSString *revenueImpressionId __unused = revenueWithPlacement.impressionId;
        NSInteger revenueMicros __unused = revenueWithPlacement.revenueMicros;
        NSString *currency __unused = revenueWithPlacement.currency;
        RCAdRevenuePrecision *precision __unused = revenueWithPlacement.precision;

        // AdTracker API
        RCAdTracker *adTracker __unused = RCPurchases.sharedPurchases.adTracker;

        // AdTracker methods with completion handlers
        [adTracker trackAdDisplayed:displayedWithPlacement completion:^{
            // Completion handler
        }];

        [adTracker trackAdOpened:openedWithPlacement completion:^{
            // Completion handler
        }];

        [adTracker trackAdRevenue:revenueWithPlacement completion:^{
            // Completion handler
        }];
    }
}

@end

#endif
