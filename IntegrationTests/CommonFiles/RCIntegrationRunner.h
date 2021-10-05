//
//  RCIntegrationRunner.h
//  CocoapodsIntegration
//
//  Created by Andrés Boedo on 10/27/20.
//

#import <Foundation/Foundation.h>
@class RCCustomerInfo;

NS_ASSUME_NONNULL_BEGIN

@interface RCIntegrationRunner : NSObject

- (void)start;

- (void)customerInfoWithCompletion:(void (^)(RCCustomerInfo * _Nullable, NSError * _Nullable))completion
NS_SWIFT_NAME(customerInfo(_:));

@end

NS_ASSUME_NONNULL_END
