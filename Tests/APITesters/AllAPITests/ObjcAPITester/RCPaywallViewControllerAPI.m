//
//  RCPaywallViewControllerAPI.m
//  ObjCAPITester
//
//  Created by RevenueCat on 2026.
//

#import "RCPaywallViewControllerAPI.h"

@import RevenueCatUI;

@interface TestObjCPurchaseHandler : NSObject <RCPaywallPurchaseHandler>
@end

@implementation TestObjCPurchaseHandler

- (void)performPurchaseFor:(RCPackage *)package
                completion:(void (^)(BOOL, NSError * _Nullable))completion {
    completion(NO, nil);
}

- (void)performRestoreWithCompletion:(void (^)(BOOL, NSError * _Nullable))completion {
    completion(YES, nil);
}

@end

@interface TestObjCPurchaseHandlerWithContext : NSObject <RCPaywallPurchaseHandlerWithContext>
@end

@implementation TestObjCPurchaseHandlerWithContext

- (void)performPurchaseWith:(RCPaywallPurchaseContext *)context
                completion:(void (^)(BOOL, NSError * _Nullable))completion {
    RCPackage *__unused package = context.package;
    RCPromotionalOffer *__unused offer = context.promotionalOffer;
    completion(NO, nil);
}

- (void)performRestoreWithCompletion:(void (^)(BOOL, NSError * _Nullable))completion {
    completion(YES, nil);
}

@end

@implementation RCPaywallViewControllerAPI

+ (void)checkAPI {
    if (@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)) {
        RCPaywallViewController *controller = [[RCPaywallViewController alloc] init];

        TestObjCPurchaseHandlerWithContext *contextHandler = [[TestObjCPurchaseHandlerWithContext alloc] init];
        RCPaywallViewController *__unused controllerWithContext =
            [[RCPaywallViewController alloc] initWithOffering:nil
                                          displayCloseButton:NO
                                     shouldBlockTouchEvents:NO
                                 purchaseHandlerWithContext:contextHandler
                                    dismissRequestedHandler:nil];
        RCPaywallFooterViewController *__unused footerWithContext =
            [[RCPaywallFooterViewController alloc] initWithOffering:nil
                                         purchaseHandlerWithContext:contextHandler
                                            dismissRequestedHandler:nil];

        // Custom Variables ObjC API
        [controller setCustomVariable:@"John" forKey:@"player_name"];

        // PaywallPurchaseHandler-based init
        TestObjCPurchaseHandler *handler = [[TestObjCPurchaseHandler alloc] init];
        RCPaywallViewController *__unused controllerWithHandler =
            [[RCPaywallViewController alloc] initWithOffering:nil
                                          displayCloseButton:NO
                                     shouldBlockTouchEvents:NO
                                            purchaseHandler:handler
                                    dismissRequestedHandler:nil];
        RCPaywallViewController *__unused controllerWithNilHandler =
            [[RCPaywallViewController alloc] initWithOffering:nil
                                          displayCloseButton:NO
                                     shouldBlockTouchEvents:NO
                                            purchaseHandler:nil
                                    dismissRequestedHandler:nil];

        // PaywallFooterViewController with PaywallPurchaseHandler
        RCPaywallFooterViewController *__unused footerWithHandler =
            [[RCPaywallFooterViewController alloc] initWithOffering:nil
                                                    purchaseHandler:handler
                                            dismissRequestedHandler:nil];
        RCPaywallFooterViewController *__unused footerWithNilHandler =
            [[RCPaywallFooterViewController alloc] initWithOffering:nil
                                                    purchaseHandler:nil
                                            dismissRequestedHandler:nil];
    }
}

@end
