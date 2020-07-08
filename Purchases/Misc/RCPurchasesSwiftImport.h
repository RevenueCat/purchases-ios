//
//  RCPurchasesSwiftImport.h
//  Purchases
//
//  Created by Andrés Boedo on 7/1/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

#if SWIFT_PACKAGE
@import PurchasesSwift;
#elif __has_include("Purchases-Swift.h")
#import "Purchases-Swift.h"
#else
#import <Purchases/Purchases-Swift.h>
#endif
