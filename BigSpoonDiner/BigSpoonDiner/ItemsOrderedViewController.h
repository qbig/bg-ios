//
//  itemsOrderedTableViewController.h
//  BigSpoonDiner
//
//  Created by Zhixing Yang on 29/10/13.
//  Copyright (c) 2013 nus.cs3217. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Order.h"

#import "NewOrderCell.h"
#import "PastOrderCell.h"
#import "Dish.h"

@class ItemsOrderedViewController;

@protocol PlaceOrderDelegate <NSObject>

- (Order *) addDishWithID: (int) dishID;
- (Order *) minusDishWithID: (int) dishID;
- (void) placeOrder;
- (Order *) getCurrentOrder;
- (Order *) getPastOrder;

@end

@interface ItemsOrderedViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) id <PlaceOrderDelegate> delegate;
@property (nonatomic, strong) Order *currentOrder;
@property (nonatomic, strong) Order *pastOrder;


- (IBAction)plusButtonPressed:(UIButton *)sender forEvent:(UIEvent *)event;
- (IBAction)minusButtonPressed:(UIButton *)sender forEvent:(UIEvent *)event;

@property (strong, nonatomic) IBOutlet UITableView *currentOrderTableView;
@property (strong, nonatomic) IBOutlet UITableView *pastOrderTableView;

- (IBAction)placeOrderButtonPressed:(id)sender;

- (void)reloadOrderTablesWithCurrentOrder:(Order*) currentOrder andPastOrder:(Order*) pastOrder;
- (IBAction)textFinishEditing:(id)sender;

@end