//
//  RCPurchasesDiagnosticsAPI.m
//  ObjCAPITester
//
//  Created by Nacho Soto on 10/10/22.
//

#import "RCPurchasesDiagnosticsAPI.h"

@import RevenueCat;

@implementation RCPurchasesDiagnosticsAPI

+ (void)checkAPI {
    if (@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)) {
        RCPurchasesDiagnostics *diagnostics = [RCPurchasesDiagnostics default];
        [diagnostics testSDKHealthWithCompletion:^(NSError * _Nullable error) {}];
    }
}

@end
