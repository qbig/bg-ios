//
//  MenuViewController.m
//  BigSpoonDiner
//
//  Created by Zhixing Yang on 15/10/13.
//  Copyright (c) 2013 nus.cs3217. All rights reserved.
//

#import "MenuViewController.h"

@interface MenuViewController (){
    void (^taskAfterAskingForTableID)(void);
    NSMutableDictionary *_viewControllersByIdentifier;
    NSString *notesWhenPlacingOrder;
    CGRect oldFrameItemBadge;
    CLGeocoder *geocoder;
	CLPlacemark *placemark;
    CLLocationManager *locationManager;
    CLLocation *currentUserLocation;
}

@property (nonatomic, strong) UIAlertView *requestForWaiterAlertView;
@property (nonatomic, strong) UIAlertView *requestForBillAlertView;
@property (nonatomic, strong) UIAlertView *inputTableIDAlertView;
@property (nonatomic, strong) UIAlertView *placeOrderAlertView;
@property (nonatomic, strong) UIAlertView *goBackButtonPressedAlertView;
@property (nonatomic, strong) UIAlertView *afterRequestBillAlertView;

@property (nonatomic, copy) void (^taskAfterAskingForTableID)(void);

- (BOOL) isUserLocation:(CLLocation *)userLocation WithinMeters:(double)radius OfLatitude:(double)lat AndLongitude:(double)lon;
- (BOOL) isLocation:(CLLocation *)locationA SameAsLocation:(CLLocation *)locationB;

@end

@implementation MenuViewController

@synthesize outlet;
@synthesize menuListViewController;
@synthesize requestWaterView;

@synthesize quantityOfColdWater;
@synthesize quantityOfWarmWater;

@synthesize quantityOfColdWaterLabel;
@synthesize quantityOfWarmWaterLabel;
@synthesize requestForWaiterAlertView;
@synthesize requestForBillAlertView;
@synthesize inputTableIDAlertView;
@synthesize taskAfterAskingForTableID;
@synthesize navigationItem;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tableID = -1;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Record the frame of badge
    oldFrameItemBadge = self.itemQuantityLabelBackgroundImageView.frame;
    
    // Set the Outlet Name to be the title
    [self.navigationItem setTitle: [self regulateLengthOfString: self.outlet.name]];
    _viewControllersByIdentifier = [NSMutableDictionary dictionary];
    
    // If the ordered items are null, init them.
    // If not, update the badge.
    if ([self.currentOrder getTotalQuantity] + [self.pastOrder getTotalQuantity] == 0) {
        self.currentOrder = [[Order alloc]init];
        self.pastOrder = [[Order alloc]init];
    } else{
        [self updateItemQuantityBadge];
    }
    
    // The toolbar that contains the bar button items
    // The toolbar is hidden (set in storyboard, x = -100)
    // Its bar button items is inserted to the navigationController
    // The buttons are hidden by default. Because don't wanna show their moving trace.
    // They will shown in viewDidAppear:
    self.navigationItem.rightBarButtonItems =
    [NSArray arrayWithObjects: self.settingsBarButton, self.viewModeBarButton, nil];
    
    //initialize geolocation
    locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	locationManager.distanceFilter = kCLDistanceFilterNone;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    //Geofencing starts working as soon as this view is loaded
    [locationManager startUpdatingLocation];
    
    [self loadControlPanels];

}

- (void) loadControlPanels{
    NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"RequestWaterView" owner:self options:nil];
    self.requestWaterView = [subviewArray objectAtIndex:0];
    [self.view addSubview:self.requestWaterView];
    CGRect frame = self.requestWaterView.frame;
    [self.requestWaterView setFrame:CGRectMake(REQUEST_WATER_VIEW_X, REQUEST_WATER_VIEW_Y, frame.size.width, frame.size.height)];
    [BigSpoonAnimationController animateTransitionOfUIView:self.requestWaterView willShow:NO];
    
}


-(void) viewDidAppear:(BOOL)animated {
    
    // Put back the button
    self.navigationItem.rightBarButtonItems =
    [NSArray arrayWithObjects: self.settingsBarButton, self.viewModeBarButton, nil];
    
    [super viewDidAppear:animated];
    
    if (self.childViewControllers.count < 1) {
        [self performSegueWithIdentifier:@"SegueFromMenuToList" sender:self];
    }
    
    // If the user is currently viewing the selected items, we should hide the "viewModeButton"
    // Because its function is replaced by the "< Menu" button at the top-left
    if ([self.destinationIdentifier isEqualToString:@"SegueFromMenuToItems"]) {
        [self.viewModeButton setHidden:YES];
        [self.settingsButton setHidden:NO];
    } else{
        [self.viewModeButton setHidden:NO];
        [self.settingsButton setHidden:NO];
    }

}

- (void) viewWillDisappear:(BOOL)animated{
    
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        
        NSString *message = @"";
        if ([self.currentOrder getTotalQuantity] != 0) {
            message = @"You have selected some food but haven't placed the order. You can come back later to place the order";
        }
        if ([self.pastOrder getTotalQuantity] != 0){
            message = @"You have unpaid items. You can come back later to pay the bill";
        }
        if ([self.currentOrder getTotalQuantity] != 0 && [self.pastOrder getTotalQuantity] != 0) {
            message = @"You have unorderd and unpaid items. You can come back later";
        }
        
        // If the user has selected/ordered anything:
        if (![message isEqualToString:@""]) {
            
            UIAlertView *alertView = [[UIAlertView alloc]
                                                 initWithTitle:nil
                                                 message:message
                                                 delegate:self
                                                 cancelButtonTitle:nil
                                                 otherButtonTitles:@"Okay", nil];
            
            [alertView show];
            
            [self.delegate exitMenuListWithCurrentOrder:self.currentOrder
                                              PastOrder:self.pastOrder
                                               OutletID:self.outlet.outletID
                                             andTableID:self.tableID];

        }
    }
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Geo Location

// Failed to get current location
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	return;
    UIAlertView *errorAlert = [[UIAlertView alloc]
							   initWithTitle:@"Error"
                               message:@"Failed to Get Your Location"
                               delegate:nil
                               cancelButtonTitle:nil
                               otherButtonTitles:@"Okay", nil];
    // Call alert
	[errorAlert show];
}

- (BOOL) isUserLocation:(CLLocation *)userLocation WithinMeters:(double)radius OfLatitude:(double)lat AndLongitude:(double)lon
{
    CLLocation *outletLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
    CLLocationDistance distance = [userLocation distanceFromLocation:outletLocation];
    if (distance <= radius) {
        return true;
    } else {
        return false;
    }
}

- (BOOL) isLocation:(CLLocation *)locationA SameAsLocation:(CLLocation *)locationB {
    if ((locationA.coordinate.latitude == locationB.coordinate.latitude) && (locationA.coordinate.longitude == locationB.coordinate.longitude)) {
        return true;
    }
    else {
        return false;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	if (![self isLocation:currentUserLocation SameAsLocation:newLocation]) {
        currentUserLocation = newLocation;
    }
}

- (NSString *) regulateLengthOfString:(NSString *)String{
    NSString *toReturn = String;
    if ([String length] >= MAX_NUM_OF_CHARS_IN_NAVIGATION_ITEM) {
        toReturn = [String substringToIndex: MAX_NUM_OF_CHARS_IN_NAVIGATION_ITEM - 3];
        toReturn = [toReturn stringByAppendingString:@"..."];
    }
    return toReturn;
}

#pragma mark ButtonClick Event Listeners

- (IBAction)viewModeButtonPressedAtListPage:(id)sender {
    NSLog(@"viewModeButtonPressedAtListPage");
    if (self.menuListViewController.displayMethod == kMethodList){
        self.menuListViewController.displayMethod = kMethodPhoto;
        [self changeViewModeButtonIconTo:@"list_icon.png"];
    } else if (self.menuListViewController.displayMethod == kMethodPhoto){
        self.menuListViewController.displayMethod = kMethodList;
        [self changeViewModeButtonIconTo:@"photo_icon.png"];
    } else {
        NSLog(@"Error: In viewModeButtonPressedAtListPage(), displayMethod not found");
    }
    
    [self.menuListViewController.tableView reloadData];
}

- (IBAction)viewModeButtonPressedAtOrderPage:(id)sender{
    NSLog(@"viewModeButtonPressedAtOrderPage");
    // Change the function of button to: Go Back.
    [self.viewModeButton removeTarget:self action:@selector(viewModeButtonPressedAtOrderPage:) forControlEvents:UIControlEventTouchUpInside];
    [self.viewModeButton addTarget:self action:@selector(viewModeButtonPressedAtListPage:) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.menuListViewController.displayMethod == kMethodPhoto){
        [self changeViewModeButtonIconTo:@"list_icon.png"];
    } else{
        [self changeViewModeButtonIconTo:@"photo_icon.png"];
    }
    
    [self changeBackButtonTo:@"home_with_arrow.png" withAction:@selector(goToHomePage)];
    
    [self.viewModeButton setHidden:NO];
    
    [self performSegueWithIdentifier:@"SegueFromMenuToList" sender:self];
}

- (void) goToHomePage{
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)settingsButtonPressed:(id)sender {

    [self performSegueWithIdentifier:@"SegueFromMenuListToOrderHistory" sender:self];
}

- (IBAction)requestWaterButtonPressed:(id)sender {
    NSLog(@"requestWaterButtonPressed");
    [BigSpoonAnimationController animateRequestButtonWhenClicked:self.requestWaterButtonCoverView];

    if (![self isTableIDKnown]) {
        [self askForTableID];
        
        __weak MenuViewController *weakSelf = self;
        
        self.taskAfterAskingForTableID = ^(void){
            [weakSelf performRequestWaterSelectQuantityPopUp];
        };
    } else{
        [self performRequestWaterSelectQuantityPopUp];
    }
}

- (void) performRequestWaterSelectQuantityPopUp{
    [BigSpoonAnimationController animateTransitionOfUIView:self.requestWaterView willShow:YES];
}

- (IBAction)requestWaiterButtonPressed:(id)sender {
    [BigSpoonAnimationController animateRequestButtonWhenClicked:self.requestWaiterButtonCoverView];
    NSLog(@"callWaiterButtonPressed");
    
    if (![self isTableIDKnown]) {
        [self askForTableID];
        
        __weak MenuViewController *weakSelf = self;
        
        self.taskAfterAskingForTableID = ^(void){
            [weakSelf performRequestWaiterConfirmationPopUp];
        };
    } else{
        [self performRequestWaiterConfirmationPopUp];
    }
}

- (void) performRequestWaiterConfirmationPopUp{
    self.requestForWaiterAlertView = [[UIAlertView alloc]
                                 initWithTitle:@"Call For Service"
                                 message:@"Require assistance from the waiter?"
                                 delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@"Yes", nil];
    [self.requestForWaiterAlertView show];
}

- (IBAction)requestBillButtonPressed:(id)sender {
    NSLog(@"billButtonPressed");
    
    [BigSpoonAnimationController animateRequestButtonWhenClicked:self.requestBillButtonCoverView];

    
    // If the user hasn't ordered anything:
    if ([self.pastOrder getTotalQuantity] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                     initWithTitle:@"Request Bill"
                                     message:@"You haven't ordered anything."
                                     delegate:nil
                                     cancelButtonTitle:nil
                                     otherButtonTitles:@"Okay", nil];
        [alertView show];
        
        return;
    }
    
    if (![self isTableIDKnown]) {
        [self askForTableID];
        
        __weak MenuViewController *weakSelf = self;
        
        self.taskAfterAskingForTableID = ^(void){
            [weakSelf performRequestBillConfirmationPopUp];
        };
    } else{
        [self performRequestBillConfirmationPopUp];
    }
}

- (void) performRequestBillConfirmationPopUp{
    
    NSMutableString *message = [[NSMutableString alloc] init];
    
    // Append the price information to the message:
    float subtotal = [self.pastOrder getTotalPrice];
    float gst = subtotal * self.outlet.gstRate;
    float serviceCharge = subtotal * self.outlet.serviceChargeRate;
    float totalPrice = subtotal + gst + serviceCharge;
    
    [message appendFormat:@"Subtotal: %.2f\n", subtotal];
    [message appendFormat:@"GST(%.0f%%): %.2f\n", self.outlet.gstRate * 100, gst];
    [message appendFormat:@"Service Charge(%.0f%%): %.2f\n", self.outlet.serviceChargeRate * 100, serviceCharge];
    [message appendFormat:@"Total: %.2f", totalPrice];
    
    self.requestForBillAlertView = [[UIAlertView alloc]
                               initWithTitle:@"Would you like your bill?"
                               message:message
                               delegate:self
                               cancelButtonTitle:@"Cancel"
                               otherButtonTitles:@"Yes", nil];
    [self.requestForBillAlertView show];
}

- (void) performRequestBillNetWorkRequest{
    
    NSMutableArray *dishesArray = [[NSMutableArray alloc] init];
    
    // For every dish that is currently in the order, we add it to the dishes dictionary:
    for (int i = 0; i < [self.currentOrder.dishes count]; i++) {
        Dish *dish = [self.currentOrder.dishes objectAtIndex:i];
        NSNumber * quantity = [NSNumber numberWithInt:[self.currentOrder getQuantityOfDishByDish: dish]];
        NSString * ID = [NSString stringWithFormat:@"%d", dish.ID];
        
        NSDictionary *newPair = [NSDictionary dictionaryWithObject:quantity forKey:ID];
        [dishesArray addObject:newPair];
    }
    
    NSDictionary *parameters = @{
                                 @"table": [NSNumber numberWithInt: self.tableID],
                                 };
    
    User *user = [User sharedInstance];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString: BILL_URL]];
    [request setValue: [@"Token " stringByAppendingString:user.auth_token] forHTTPHeaderField: @"Authorization"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    request.HTTPBody = jsonData;
    request.HTTPMethod = @"POST";
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    [operation  setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        int responseCode = [operation.response statusCode];
        switch (responseCode) {
            case 200:
            case 201:{
                NSLog(@"Request Bill Success");
                [self afterSuccessfulRequestBill];
            }
                break;
            case 403:
            default:{
                NSLog(@"Request Bill Fail");
                [self displayErrorInfo: operation.responseObject];
            }
        }
        NSLog(@"JSON: %@", responseObject);
    }
                                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                          [self displayErrorInfo: operation.responseObject];
                                      }];
    
    [operation start];
}

- (void) afterSuccessfulRequestBill{
    self.afterRequestBillAlertView = [[UIAlertView alloc]
                              initWithTitle:@"Call For Bill"
                              message:@"The waiter will be right with you"
                              delegate:self
                              cancelButtonTitle:@"Okay"
                              otherButtonTitles:nil];
    [self.afterRequestBillAlertView show];
    
    // After the "OK" button is clicked, [self afterRequestBillAlertViewOkayButtonClicked] will be clicked;
}

- (void) afterRequestBillAlertViewOkayButtonClicked{
    
    NSLog(@"asdfasdfasfdasdfasdf");
    
    // Load and show the ratingAndFeedbackViewController:
    
    // Initialize the controller and the view
    self.ratingAndFeedbackViewController = [[RatingAndFeedbackViewController alloc] init];
    self.ratingsAndFeedbackView = self.ratingAndFeedbackViewController.view;
    
    // Make the frame correct:
    CGRect frame = self.ratingAndFeedbackViewController.view.frame;
    [self.ratingsAndFeedbackView setFrame:CGRectMake(RATING_AND_FEEDBACK_X,
                                                    RATING_AND_FEEDBACK_Y,
                                                    frame.size.width,
                                                    frame.size.height)];
    
    // Load data
    [self.ratingAndFeedbackViewController reloadDataWithOrder: self.pastOrder andOutletID:self.outlet.outletID];
    
    // Add subview and make it appear
    [self.view addSubview: self.ratingsAndFeedbackView];
    [BigSpoonAnimationController animateTransitionOfUIView:self.ratingsAndFeedbackView willShow:YES];
    
    // After everything, set the order items to null
    self.currentOrder = [[Order alloc] init];
    self.pastOrder = [[Order alloc] init];
    self.tableID = -1;
}

- (IBAction)itemsButtonPressed:(id)sender {
    NSLog(@"itemsButtonPressed");
    [BigSpoonAnimationController animateRequestButtonWhenClicked:self.itemsButtonCoverView];
    
    // Can also check in the shouldPerformSegueWithIdentifier:sender
    // But it doesn't work because it's manual segue
    if (![self.destinationIdentifier isEqualToString:@"SegueFromMenuToItems"]) {
        [self performSegueWithIdentifier:@"SegueFromMenuToItems" sender:self];
    }
}

- (void) changeViewModeButtonIconTo: (NSString *)picName{
    [self.viewModeButton setImage:[UIImage imageNamed:picName] forState:UIControlStateNormal];
    [self.viewModeButton setImage:[UIImage imageNamed:picName] forState:UIControlStateHighlighted];
}

- (void) changeBackButtonTo: (NSString *)picName withAction: (SEL) sel{
    
    UIImage *buttonImage = [UIImage imageNamed:picName];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];

    [button setImage:buttonImage forState:UIControlStateNormal];
    
    button.frame = CGRectMake(0, 0, 23 * SCALE_OF_BUTTON, 23); // Ratio: 128 * 46
    
    [button addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *customBarItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    self.navigationItem.leftBarButtonItem = customBarItem;

}

#pragma mark tableViewController Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSLog(@"Asked, hay!");
    return 4;
}

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"SegueFromMenuListToOrderHistory"]) {
        
        // Need to set the rightBarButtonItems to nil. Otherwise they will slide to the left.
        // They will be put back after viewDidAppear: function. That function will be called after the new view is poped.
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects: nil];
        
        NSString *backButtonTitle = @"";
        if ([self.destinationIdentifier isEqualToString:@"SegueFromMenuToItems"]) {
            backButtonTitle = @"Items";
        } else if ([self.destinationIdentifier isEqualToString:@"SegueFromMenuToList"]) {
            backButtonTitle = @"Menu";
        }
        
        // Change the back button title. Cannot display title of restaurant, since it's too long to appear in the back button.
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: backButtonTitle style: UIBarButtonItemStyleBordered target: nil action: nil];
        [[self navigationItem] setBackBarButtonItem: newBackButton];
        
	} else if([segue isKindOfClass:[MultiContainerViewSegue class]]){
        
        self.oldViewController = self.destinationViewController;
        
        //if view controller isn't already contained in the viewControllers-Dictionary
        if (![_viewControllersByIdentifier objectForKey:segue.identifier]) {
            
            NSLog(@"New viewController generated when performing segue: %@", segue.identifier);
            
            [_viewControllersByIdentifier setObject:segue.destinationViewController forKey:segue.identifier];
            
            if ([segue.identifier isEqualToString:@"SegueFromMenuToList"]){
                
                self.menuListViewController = segue.destinationViewController;
                self.menuListViewController.outlet = self.outlet;
                self.menuListViewController.delegate = self;
                
            } else if ([segue.identifier isEqualToString:@"SegueFromMenuToItems"]){
                
                self.itemsOrderedViewController = (ItemsOrderedViewController *)segue.destinationViewController;
                self.itemsOrderedViewController.delegate = self;
            }
        }
        
        self.destinationIdentifier = segue.identifier;
        self.destinationViewController = [_viewControllersByIdentifier objectForKey:self.destinationIdentifier];
        
        if ([segue.identifier isEqualToString:@"SegueFromMenuToList"]){
            
            NSLog(@"Going SegueFromMenuToList");
        
        }
        
        if([segue.identifier isEqualToString:@"SegueFromMenuToItems"]){

            NSLog(@"Going SegueFromMenuToItems");
            
            // Make a new goBackButton
            [self changeBackButtonTo:@"back.png" withAction:@selector(viewModeButtonPressedAtOrderPage:)];
            
            // Change the function of button to: Go Back.
            [self.viewModeButton setHidden:YES];
            
            [self.itemsOrderedViewController setGSTRate: outlet.gstRate andServiceChargeRate:outlet.serviceChargeRate];
            
            [self.itemsOrderedViewController reloadOrderTablesWithCurrentOrder:self.currentOrder andPastOrder:self.pastOrder];
        }
        
    } else{
        NSLog(@"Segure in the menuViewController cannot assign delegate to its segue. Segue identifier: %@", segue.identifier);
    }
}

- (void) cancelButtonPressed:(OrderHistoryViewController *)controller{
    NSLog(@"cancelled");
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([alertView isEqual:self.requestForBillAlertView]) {
        if([title isEqualToString:@"Yes"])
        {
            NSLog(@"Request For Bill");
            // TODO Make HTTP request for this.
            [self performRequestBillNetWorkRequest];
        }
        else if([title isEqualToString:@"Cancel"])
        {
            NSLog(@"Request For bill Canceled");
        }else{
            NSLog(@"Unrecognized button pressed");
        }
    }
    
    else if ([alertView isEqual:self.requestForWaiterAlertView]){
        if([title isEqualToString:@"Yes"])
        {
            NSLog(@"Request For Waiter");
            
            [self requestWithType:@1 WithNote:@"Request For Waiter"];
        }
        else if([title isEqualToString:@"Cancel"])
        {
            NSLog(@"Request For waiter Canceled");
        }else{
            NSLog(@"Unrecognized button pressed");
        }
    }
    
    else if ([alertView isEqual:self.inputTableIDAlertView]){

        if(![title isEqualToString:@"Cancel"])
        {
            NSString *name = [alertView textFieldAtIndex:0].text;
            int value = [name integerValue];
            NSLog(@"User input ID: %d", value);
            
            for (NSNumber *validID in self.validTableIDs) {
                if ([validID integerValue] == value) {
                    NSLog(@"The table ID is valid");
                    self.tableID = value;
                    self.taskAfterAskingForTableID();
                    return;
                }
            }
            [self askForTableIDWithTitle:@"Please enter a valid table ID"];
        }
    }
    
    else if ([alertView isEqual:self.placeOrderAlertView]){
        
        NSLog(@"Place Order Alert View Clicked");
    
        if(![title isEqualToString:@"Cancel"])
        {
            [self performPlaceOrderNetWorkRequest];
        }
        
    }
    
    else if ([alertView isEqual:self.goBackButtonPressedAlertView]){
        [self.navigationController popViewControllerAnimated:NO];
    }
    
    else if ([alertView isEqual:self.afterRequestBillAlertView]){
        [self afterRequestBillAlertViewOkayButtonClicked];
    }
    
    else{
        NSLog(@"In alertView delegateion method: No alertview found.");
    }
}

- (void) dishOrdered:(Dish *)dish{
    [self.currentOrder addDish:dish];
    [self updateItemQuantityBadge];
}

- (void) orderQuantityHasChanged:(Order *)order{
    NSLog(@"MenuViewController Detected Order Change");
    [self updateItemQuantityBadge];
}

- (void) updateItemQuantityBadge{
    
    int totalQuantity = [self.currentOrder getTotalQuantity];
    
    if (totalQuantity == 0) {
        [self.itemQuantityLabel setHidden:YES];
        [self.itemQuantityLabelBackgroundImageView setHidden:YES];
    } else{
        [self.itemQuantityLabel setHidden:NO];
        [self.itemQuantityLabelBackgroundImageView setHidden:NO];
        self.itemQuantityLabel.text = [NSString stringWithFormat:@"%d", totalQuantity];
        
        // Animation of the red badge:
       [BigSpoonAnimationController animateBadgeAfterUpdate: self.itemQuantityLabelBackgroundImageView
                                          withOriginalFrame: oldFrameItemBadge];
    }
}

- (void)validTableRetrieved: (NSArray *)vIDs{
    self.validTableIDs = vIDs;
}

// PlaceOrderDelegate:
- (Order *) addDishWithID: (int) dishID{
    Dish *dish = [self.menuListViewController getDishWithID:dishID];
    [self.currentOrder addDish:dish];
    [self updateItemQuantityBadge];
    
    return self.currentOrder;
}

- (Order *) minusDishWithID: (int) dishID{
    Dish *dish = [self.menuListViewController getDishWithID:dishID];
    [self.currentOrder minusDish:dish];
    [self updateItemQuantityBadge];
    
    return self.currentOrder;
}

- (void) placeOrderWithNotes:(NSString *)notes{
    
    // If the user hasn't ordered anything:
    if ([self.currentOrder getTotalQuantity] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Place Order"
                                  message:@"You haven't selected anything."
                                  delegate:nil
                                  cancelButtonTitle:@"Okay"
                                  otherButtonTitles:nil];
        [alertView show];
        
        return;
    }
    
    NSLog(@"Placing order");
    
    notesWhenPlacingOrder = notes;
    
    if (![self isTableIDKnown]) {
        [self askForTableID];
        
        __weak MenuViewController *weakSelf = self;
        
        self.taskAfterAskingForTableID = ^(void){
            [weakSelf performPlaceOrderConfirmationPopUp];
        };
    } else{
        [self performPlaceOrderConfirmationPopUp];
    }
}

- (void) performPlaceOrderConfirmationPopUp{
    
    NSMutableString *message = [[NSMutableString alloc] init];
    
    // For every dish that is currently in the order, we print out something like: "3X Samon Fish"
    for (int i = 0; i < [self.currentOrder.dishes count]; i++) {
        Dish *dish = [self.currentOrder.dishes objectAtIndex:i];
        [message appendFormat:@"%dX %@\n", [self.currentOrder getQuantityOfDishByDish: dish], dish.name];
    }
    
     self.placeOrderAlertView = [[UIAlertView alloc]
                              initWithTitle:@"New Order"
                              message: message
                              delegate:self
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"Okay", nil];
    [self.placeOrderAlertView show];
}

- (void) performPlaceOrderNetWorkRequest{
    
    NSMutableArray *dishesArray = [[NSMutableArray alloc] init];
    
    // For every dish that is currently in the order, we add it to the dishes dictionary:
    for (int i = 0; i < [self.currentOrder.dishes count]; i++) {
        Dish *dish = [self.currentOrder.dishes objectAtIndex:i];
        NSNumber * quantity = [NSNumber numberWithInt:[self.currentOrder getQuantityOfDishByDish: dish]];
        NSString * ID = [NSString stringWithFormat:@"%d", dish.ID];
        
        NSDictionary *newPair = [NSDictionary dictionaryWithObject:quantity forKey:ID];
        [dishesArray addObject:newPair];
    }
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:[NSArray arrayWithArray: dishesArray] forKey:@"dishes"];
    [parameters setObject:[NSNumber numberWithInt: self.tableID] forKey:@"table"];
    if (notesWhenPlacingOrder != nil && ![notesWhenPlacingOrder isEqualToString:@""] ) {
        [parameters setObject:notesWhenPlacingOrder forKey:@"note"];
    }

    User *user = [User sharedInstance];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString: ORDER_URL]];
    [request setValue: [@"Token " stringByAppendingString:user.auth_token] forHTTPHeaderField: @"Authorization"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    request.HTTPBody = jsonData;
    request.HTTPMethod = @"POST";
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    [operation  setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        int responseCode = [operation.response statusCode];
        switch (responseCode) {
            case 200:
            case 201:{
                NSLog(@"Place Order Success");
                [self afterSuccessfulPlacedOrder];
            }
                break;
            case 403:
            default:{
                NSLog(@"Place Order Fail");
                [self displayErrorInfo: operation.responseObject];
            }
        }
        NSLog(@"JSON: %@", responseObject);
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Place Order failure: %@", operation.responseString);
        [self displayErrorInfo: operation.responseObject];
    }];
    
    [operation start];
}

- (void) afterSuccessfulPlacedOrder{
    [self.pastOrder mergeWithAnotherOrder:self.currentOrder];
    self.currentOrder = [[Order alloc] init];
    [self.itemsOrderedViewController reloadOrderTablesWithCurrentOrder:self.currentOrder andPastOrder:self.pastOrder];
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Your order has been sent"
                              message:@"Thank you for waiting"
                              delegate:nil
                              cancelButtonTitle:@"Okay"
                              otherButtonTitles:nil];
    [alertView show];
    
    [self updateItemQuantityBadge];
}

- (Order *) getCurrentOrder{
    return self.currentOrder;
}

- (Order *) getPastOrder{
    return self.pastOrder;
}

#pragma mark Request For Service (water and waiter)

- (IBAction)plusColdWaterButtonPressed:(id)sender {
    self.quantityOfColdWater++;
    self.quantityOfColdWaterLabel.text = [NSString stringWithFormat:@"%d", quantityOfColdWater];
}

- (IBAction)minusColdWaterButtonPressed:(id)sender {
    if (self.quantityOfColdWater > 0) {
        self.quantityOfColdWater--;
        self.quantityOfColdWaterLabel.text = [NSString stringWithFormat:@"%d", quantityOfColdWater];
    }
}

- (IBAction)plusWarmWaterButtonPressed:(id)sender {
    self.quantityOfWarmWater++;
    self.quantityOfWarmWaterLabel.text = [NSString stringWithFormat:@"%d", quantityOfWarmWater];
}

- (IBAction)minusWarmWaterButtonPressed:(id)sender {
    if (self.quantityOfWarmWater > 0) {
        self.quantityOfWarmWater--;
        self.quantityOfWarmWaterLabel.text = [NSString stringWithFormat:@"%d", quantityOfWarmWater];
    }
}

- (IBAction)requestWaterOkayButtonPressed:(id)sender {
    
    if (self.quantityOfColdWater != 0 || self.quantityOfWarmWater != 0) {
        NSString *note = [NSString stringWithFormat:@"Cold Water: %d cups. Warm Water: %d cups", self.quantityOfColdWater, self.quantityOfWarmWater];
        [self requestWithType:@0 WithNote:note];
    }
    
    [self requestWaterCancelButtonPressed:nil];
}

- (void) requestWithType: (id) requestType WithNote: (NSString *)note{
    NSDictionary *parameters = @{
                                 @"table": [NSNumber numberWithInt: self.tableID],
                                 @"request_type": requestType,
                                 @"note": note
                                 };
    
    User *user = [User sharedInstance];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString: REQUEST_URL]];
    [request setValue: [@"Token " stringByAppendingString:user.auth_token] forHTTPHeaderField: @"Authorization"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    request.HTTPBody = jsonData;
    request.HTTPMethod = @"POST";
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    [operation  setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        int responseCode = [operation.response statusCode];
        switch (responseCode) {
            case 200:
            case 201:{
                NSLog(@"Success");
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@"Call For Service"
                                          message:@"The waiter will be right with you"
                                          delegate:nil
                                          cancelButtonTitle:@"Okay"
                                          otherButtonTitles:nil];
                [alertView show];
            }
                break;
            case 403:
            default:{
                [self displayErrorInfo: operation.responseObject];
            }
        }
        NSLog(@"JSON: %@", responseObject);
    }
                                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                          [self displayErrorInfo:operation.responseObject];
                                      }];
    [operation start];
}

- (void) displayErrorInfo: (id) responseObject{
    
    NSDictionary *dictionary = (NSDictionary *)responseObject;
    
    NSMutableString *message = [[NSMutableString alloc] init];
    
    NSArray *errorInfoArray= [dictionary allValues];
    
    for (NSString * errorInfo in errorInfoArray) {
        [message appendString:errorInfo];
    }

    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Oops"
                              message: message
                              delegate:nil
                              cancelButtonTitle:@"Okay"
                              otherButtonTitles:nil];
    [alertView show];
}

- (IBAction)requestWaterCancelButtonPressed:(id)sender {

    self.quantityOfWarmWater = 0;
    self.quantityOfColdWater = 0;
    self.quantityOfWarmWaterLabel.text = [NSString stringWithFormat:@"%d", self.quantityOfWarmWater];
    self.quantityOfColdWaterLabel.text = [NSString stringWithFormat:@"%d", self.quantityOfColdWater];
    
    [BigSpoonAnimationController animateTransitionOfUIView:self.requestWaterView willShow:NO];
}

#pragma mark - Dealing with table number

- (BOOL) isTableIDKnown{
    NSLog(@"Current table ID: %d", self.tableID);
    // If tableID is 0 or -1, we conclude that the tableID is not known from the user.
    return self.tableID > 0;
}

- (void) askForTableID{
    [self askForTableIDWithTitle: @"Please enter your table ID"];
}

- (void) askForTableIDWithTitle: (NSString *)title{
    self.inputTableIDAlertView = [[UIAlertView alloc]
                              initWithTitle: title
                              message: nil
                              delegate:self
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"Okay", nil];
    
    self.inputTableIDAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [self.inputTableIDAlertView show];
}

#pragma mark - Others


@end
