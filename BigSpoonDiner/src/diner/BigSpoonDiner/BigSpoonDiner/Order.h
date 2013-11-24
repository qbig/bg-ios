//
//  order.h
//  BigSpoonDiner
//
//  Created by Zhixing Yang on 29/10/13.
//  Copyright (c) 2013 nus.cs3217. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Dish.h"

@interface Order : NSObject

// The reason to store dishes rather than an ID is
// When the order is displayed, other information is needed.
@property (nonatomic, strong) NSMutableArray *dishes;
@property (nonatomic, strong) NSMutableArray *quantity;

// Note:
// In self.dishes, object equlity is NOT assumed, for example:
// You shall NEVER use:
//
// - [self.dishes containsObject: newDish]
// - [self.dishes indexOf: newDish]
// - [self.dishes removeObject: newDish]
//
// Instead, you should iterate through the dishes, looking for an equal ID.

- (void) addDish: (Dish *) dish;
- (void) minusDish: (Dish *) dish;

- (int) getQuantityOfDishByDish: (Dish *) dish;
- (int) getQuantityOfDishByID: (int) dishID;

- (int) getTotalQuantity;
- (double) getTotalPrice;

- (void) mergeWithAnotherOrder: (Order *)newOrder;

- (int) getNumberOfKindsOfDishes;

@end
