//
//  RCPurchaseOwnershipType.h
//  Purchases
//
//  Created by Andrés Boedo on 3/16/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, RCPurchaseOwnershipType) {
    /**
     The purchase was made directly by this user.
     */
    RCPurchaseOwnershipTypePurchased = 0,
    /**
     The purchase has been shared to this user by a family member.
     */
    RCPurchaseOwnershipTypeFamilyShared = 1,

    RCPurchaseOwnershipTypeUnknown = 2,
};
