//
//  RCVerificationResultAPI.m
//  ObjCAPITester
//
//  Created by Nacho Soto on 2/10/23.
//

@import RevenueCat;

#import "RCVerificationResultAPI.h"

@implementation RCVerificationResultAPI

+ (void)checkAPI {
    const __unused RCVerificationResult result = RCVerificationResultVerified;

    switch (result) {
        case RCVerificationResultNotVerified:
        case RCVerificationResultVerified:
        case RCVerificationResultFailed:
            break;
    }

    const __unused RCEntitlementVerificationMode mode = RCEntitlementVerificationModeDisabled;

    switch (mode) {
        case RCEntitlementVerificationModeDisabled:
        case RCEntitlementVerificationModeInformationOnly:
        case RCEntitlementVerificationModeEnforced:
            break;
    }
}

@end
