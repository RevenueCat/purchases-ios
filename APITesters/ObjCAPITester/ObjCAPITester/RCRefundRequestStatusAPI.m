//
//  RCRefundRequestStatusAPI.m
//  ObjCAPITester
//
//  Created by Madeline Beyl on 10/28/21.
//

#import "RCRefundRequestStatusAPI.h"
@import RevenueCat;

@implementation RCRefundRequestStatusAPI

+ (void) checkEnums {
    RCRefundRequestStatus status = RCRefundRequestStatusSuccess;
    switch(status) {
        case RCRefundRequestStatusSuccess:
        case RCRefundRequestStatusError:
        case RCRefundRequestStatusUserCancelled:
            NSLog(@"%ld", (long)status);
    }
}

@end
