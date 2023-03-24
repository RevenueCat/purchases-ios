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
        case RCVerificationResultNotRequested:
        case RCVerificationResultVerified:
        case RCVerificationResultVerifiedOnDevice:
        case RCVerificationResultFailed:
            break;
    }

    const __unused RCEntitlementVerificationMode mode = RCEntitlementVerificationModeDisabled;

    switch (mode) {
        case RCEntitlementVerificationModeDisabled:
        case RCEntitlementVerificationModeInformational:
        case RCEntitlementVerificationModeEnforced:
            break;
    }
}

@end
