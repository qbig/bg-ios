//
//  order.m
//  BigSpoonDiner
//
//  Created by Zhixing Yang on 29/10/13.
//  Copyright (c) 2013 nus.cs3217. All rights reserved.
//

#import "Order.h"

@interface Order ()

@end

@implementation Order

#pragma mark Public Methods

- (id) init{
    self = [super init];
    if (self) {
        // Initialization code
        self.dishes = [[NSMutableArray alloc] init];
        self.quantity = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) addDish: (Dish *) dish{
    // If added before, just update its index:
    if ([self containsDishWithDishID:dish.ID]) {
        
        int index = [self getIndexOfDishByDish:dish];
        int quantity = [self getQuantityOfDishByDish:dish];
                
        NSNumber *newQuantity = [NSNumber numberWithInt: quantity + 1];
        [self.quantity setObject:newQuantity atIndexedSubscript: index];
        
    }
    
    // If it's new, add it:
    else{
        [self.dishes addObject: dish];
        [self.quantity addObject: [NSNumber numberWithInt:1]];
    }
}

- (void) minusDish:(Dish *)dish{
    if ([self containsDishWithDishID:dish.ID]) {
        
        int index = [self getIndexOfDishByDish:dish];
        int quantity = [self getQuantityOfDishByDish:dish];
        NSNumber* quantityObject = [self getQuantityObjectOfDish:dish];
        
        // Still have more than one quantity, just decrease the number:
        if (quantity > 1) {
            NSNumber *newQuantity = [NSNumber numberWithInt: quantity - 1];
            [self.quantity setObject:newQuantity atIndexedSubscript: index];
        }
        
        // Have less than one quantity, if minus, becomes 0 quantity, so just remove it:
        else{
            [self.quantity removeObject: quantityObject];
            [self removeDishWithID:dish.ID];
        }
        
    }
}

- (int) getQuantityOfDishByDish: (Dish *) dish{
    if ([self containsDishWithDishID:dish.ID]) {
        NSNumber *quantity = [self getQuantityObjectOfDish:dish];
        // NSLog(@"Getting quantity of dish ID: %d, quantity: %d", dish.ID, quantity.integerValue);
        return quantity.integerValue;
    } else{
        return 0;
    }
}

- (int) getQuantityOfDishByID: (int) dishID{
    
    // Iterate through the dishes:
    for (int i = 0; i < [self.dishes count]; i++) {
        Dish *dish = [self.dishes objectAtIndex:i];
        if (dish.ID == dishID) {
            NSNumber *quantity = [self getQuantityObjectOfDish:dish];
            return quantity.integerValue;
        }
    }
    
    // The dishID not found:
    return 0;
}

- (int) getTotalQuantity{
    int totalQuantity = 0;
    
    for (NSNumber *n in self.quantity) {
        totalQuantity += [n integerValue];
    }
    
    return totalQuantity;
}

- (int) getTotalPrice{
    int totalPrice = 0;
    for (int i = 0; i < [self.dishes count]; i++) {
        Dish *newDish = (Dish *)[self.dishes objectAtIndex:i];
        int quantity = [self getQuantityOfDishByDish:newDish];
        
        totalPrice += newDish.price * quantity;
    }
    return totalPrice;
}

- (int) getNumberOfKindsOfDishes{
    return [self.dishes count];
}


- (void) mergeWithAnotherOrder: (Order *)newOrder{
    
    for (int i = 0; i < [newOrder getNumberOfKindsOfDishes]; i++) {
        
        Dish *newDish = (Dish *)[newOrder.dishes objectAtIndex:i];
        
        int newQuantity = [newOrder getQuantityOfDishByDish:newDish];
        
        if ([self containsDishWithDishID: newDish.ID]) {
            
            int selfQuantity = [self getQuantityOfDishByDish:newDish];
            int index = [self getIndexOfDishByDish:newDish];
            
            NSNumber *numObject = [NSNumber numberWithInt: newQuantity + selfQuantity];
            [self.quantity setObject: numObject atIndexedSubscript:index];
            
            // NSLog(@"Meging dish... Existing Dish: %d, has new quantity: %d", newDish.ID, newQuantity + selfQuantity);
            
        } else{
            
            [self.dishes addObject:newDish];
            NSNumber *newQuantityObject = [NSNumber numberWithInt:newQuantity];
            [self.quantity addObject:newQuantityObject];
            
            // NSLog(@"Meging dish... New Dish: %d, has new quantity: %d", newDish.ID, [newQuantityObject integerValue]);
            
        }
    }
}

#pragma mark Private Functions

- (NSNumber *) getQuantityObjectOfDish: (Dish *) newDish{
    int index = [self getIndexOfDishByDish:newDish];
    return (NSNumber *)[self.quantity objectAtIndex: index];
}

- (int) getIndexOfDishByDish: (Dish *) newDish{
    for (int i = 0; i < [self.dishes count]; i++) {
        Dish * myDish = [self.dishes objectAtIndex:i];
        if (myDish.ID == newDish.ID) {
            return i;
        }
    }
    return -1;
}

- (Dish *) getDishByID: (int) newDishID{
    for (Dish *dish in self.dishes) {
        if (dish.ID == newDishID) {
           // NSLog(@"Contains: %d!", dishID);
            return dish;
        }
    }
    //NSLog(@"No Contain: %d!", dishID);
    return nil;
}

- (BOOL) containsDishWithDishID: (int) newDishID{
    return [self getDishByID:newDishID] != nil;
}

- (void) removeDishWithID: (int) newDishID{
    for (Dish *dish in self.dishes) {
        if (dish.ID == newDishID) {
            // NSLog(@"Contains: %d!", dishID);
            [self.dishes removeObject: dish];
            return;
        }
    }
}

@end
