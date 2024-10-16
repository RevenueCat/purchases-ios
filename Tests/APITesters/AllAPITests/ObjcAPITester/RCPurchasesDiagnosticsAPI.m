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
    RCPurchasesDiagnostics *diagnostics = [RCPurchasesDiagnostics default];
    [diagnostics testSDKHealthWithCompletion:^(NSError * _Nullable error) {}];
}

@end
