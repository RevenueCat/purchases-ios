//
//  RCSystemInfoAPI.m
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 6/29/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

@import Foundation;
@import Purchases;

#import "RCSystemInfoAPI.h"

@implementation RCSystemInfoAPI

+ (void)checkAPI {
    RCSystemInfo *si = [[RCSystemInfo alloc] initWithPlatformFlavor:nil
                                              platformFlavorVersion:nil
                                                 finishTransactions:YES];

    BOOL ft = si.finishTransactions;
    NSString *pf = si.platformFlavor;
    NSString *pfv = si.platformFlavorVersion;
    BOOL fuas = RCSystemInfo.forceUniversalAppStore;
    BOOL isSandbox = RCSystemInfo.isSandbox;
    NSString *frameworkVersion = RCSystemInfo.frameworkVersion;
    NSString *systemVersion = RCSystemInfo.systemVersion;
    NSString *appVersion = RCSystemInfo.appVersion;
    NSString *buildVersion = RCSystemInfo.buildVersion;
    NSString *platformHeader = RCSystemInfo.platformHeader;
    NSString *identifierForVendor = RCSystemInfo.identifierForVendor;
    NSURL *serverHostURL = RCSystemInfo.serverHostURL;
    NSURL *proxyURL = RCSystemInfo.proxyURL;
    [RCSystemInfo setProxyURL:nil];
    [si isApplicationBackgroundedWithCompletion:^(BOOL tacos) {}];
    BOOL isosalv = [si isOperatingSystemAtLeastVersion:NSProcessInfo.processInfo.operatingSystemVersion];

    NSLog([NSString stringWithFormat:@"%i", ft],
          pf,
          pfv,
          [NSString stringWithFormat:@"%i", fuas],
          isSandbox,
          frameworkVersion,
          systemVersion,
          appVersion,
          buildVersion,
          platformHeader,
          identifierForVendor,
          serverHostURL,
          proxyURL,
          isosalv);
}

@end
