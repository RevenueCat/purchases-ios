//
//  RCIntegrationRunner.m
//  CocoapodsIntegration
//
//  Created by Andrés Boedo on 10/27/20.
//

#import "RCIntegrationRunner.h"
@import Purchases;

NS_ASSUME_NONNULL_BEGIN

@implementation RCIntegrationRunner

- (void)start {
    [RCPurchases setDebugLogsEnabled:true];
    [RCPurchases configureWithAPIKey:@"VtDdmbdWBySmqJeeQUTyrNxETUVkhuaJ"
                           appUserID:@"integrationTest"];
}

@end

NS_ASSUME_NONNULL_END
