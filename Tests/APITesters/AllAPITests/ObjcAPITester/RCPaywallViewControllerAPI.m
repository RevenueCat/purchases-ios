//
//  RCPaywallViewControllerAPI.m
//  ObjCAPITester
//
//  Created by RevenueCat on 2026.
//

#import "RCPaywallViewControllerAPI.h"

@import RevenueCatUI;

@implementation RCPaywallViewControllerAPI

+ (void)checkAPI {
    if (@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)) {
        RCPaywallViewController *controller = [[RCPaywallViewController alloc] init];

        // Custom Variables ObjC API
        [controller setCustomVariable:@"John" forKey:@"player_name"];
        [controller setCustomVariableNumber:100.0 forKey:@"max_health"];
        [controller setCustomVariableBool:YES forKey:@"is_premium"];
    }
}

@end
