//
//  RCOperationDispatcher.h
//  Purchases
//
//  Created by Andrés Boedo on 8/5/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(OperationDispatcher)
@interface RCOperationDispatcher : NSObject

- (void)dispatchOnMainThreadIfSet:(void (^ _Nullable)(void))block;
- (void)dispatchOnMainThread:(void (^)(void))block;
- (void)dispatchOnSameThreadIfSet:(void (^ _Nullable)(void))block;
- (void)dispatchOnWorkerThread:(void (^)(void))block;

@end

NS_ASSUME_NONNULL_END
