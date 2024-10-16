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
    RCRefundRequestStatus status = RCRefundRequestSuccess;
    switch(status) {
        case RCRefundRequestSuccess:
        case RCRefundRequestError:
        case RCRefundRequestUserCancelled:
            NSLog(@"%ld", (long)status);
    }
}

@end
