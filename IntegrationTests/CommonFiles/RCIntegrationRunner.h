//
//  RCIntegrationRunner.h
//  CocoapodsIntegration
//
//  Created by Andrés Boedo on 10/27/20.
//

#import <Foundation/Foundation.h>
@class RCPurchaserInfo;

typedef void (^RCReceivePurchaserInfoBlock) (RCPurchaserInfo * _Nullable, NSError * _Nullable);

NS_ASSUME_NONNULL_BEGIN

@interface RCIntegrationRunner : NSObject

- (void)start;

- (void)purchaserInfoWithCompletionBlock:(void (^)(RCPurchaserInfo * _Nullable, NSError * _Nullable))completion
NS_SWIFT_NAME(purchaserInfo(_:));

@end

NS_ASSUME_NONNULL_END
