//
//  RCInstallationRunner.h
//  CocoapodsInstallation
//
//  Created by Andrés Boedo on 10/27/20.
//

#import <Foundation/Foundation.h>
@class RCCustomerInfo;

NS_ASSUME_NONNULL_BEGIN

@interface RCInstallationRunner : NSObject

- (void)start;

- (void)getCustomerInfoWithCompletion:(void (^)(RCCustomerInfo * _Nullable, NSError * _Nullable))completion
NS_SWIFT_NAME(getCustomerInfo(_:));

@end

NS_ASSUME_NONNULL_END
