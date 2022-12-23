//
//  BarcodeDataTableViewController.m
//  RFIDDemoApp
//
//  Created by Sivarajah Pranavan on 2021-08-25.
//  Copyright © 2021 Zebra Technologies Corp. and/or its affiliates. All rights reserved.
//

#import "BarcodeDataTableViewController.h"
#import "ui_config.h"
#import "BarcodeFullViewController.h"
#import "ScannerEngine.h"
#import "ScannerObject.h"
#import "config.h"
#import "RfidAppEngine.h"
#import "AlertView.h"

@interface BarcodeDataTableViewController ()

@end

/// Barcode data table view controller
@implementation BarcodeDataTableViewController



/// Object initialized from data in a given unarchiver.
/// @param aDecoder An abstract class that serves as the basis for objects that enable archiving and distribution of other objects.
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil)
    {
        [[ScannerEngine sharedScannerEngine] setDelegateForScannerObject:self];
       barcodeList = [[NSMutableArray alloc] init];
    }
    return self;
}



/// Called after the controller's view is loaded into memory.
- (void)viewDidLoad {
    [super viewDidLoad];
    activityView = [[zt_AlertView alloc]init];
}

/// Notifies the view controller that its view is about to be added to a view hierarchy.
/// @param animated If YES, the view is being added to the window using an animation.
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    /* set title */
    [self.tabBarController setTitle:BARCODE_DATA_VIEW_TITLE];
    
    [[ScannerEngine sharedScannerEngine] setBarcodePageAppear:true];
    inventoryRequested = [[[zt_RfidAppEngine sharedAppEngine] operationEngine] getStateInventoryRequested];
    [[zt_RfidAppEngine sharedAppEngine] addTriggerEventDelegate:self];
    [[[zt_RfidAppEngine sharedAppEngine] operationEngine] addOperationListener:self];
    
    /* add dpo button to the titlebar */
    NSMutableArray *right_items = [[NSMutableArray alloc] init];
    [right_items addObject:barButtonDpo];
    
    self.tabBarController.navigationItem.rightBarButtonItems = right_items;
    
    [right_items removeAllObjects];
    [right_items release];

}


/// Notifies the view controller that its view was removed from a view hierarchy.
/// @param animated If YES, the disappearance of the view was animated.
-(void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];
    [[ScannerEngine sharedScannerEngine] setBarcodePageAppear:false];
    
}


/// Notifies the view controller that its view is about to be removed from a view hierarchy.
/// @param animated If true, the disappearance of the view is being animated.
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[[zt_RfidAppEngine sharedAppEngine] operationEngine] removeOperationListener:self];
    [[zt_RfidAppEngine sharedAppEngine] removeTriggerEventDelegate:self];
}

/// Notifies the view controller that its view was added to a view hierarchy.
/// @param animated If YES, the view was added to the window using an animation.
-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [self showBarcodInTableView];
}

#pragma mark - Table view data source

/// Asks the data source to return the number of sections in the table view.
/// @param tableView An object representing the table view requesting this information
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return BARCODE_DATA_VIEW_NUMBER_OF_SECTION;
}

/// Tells the data source to return the number of rows in a given section of a table view.
/// @param tableView The table-view object requesting this information.
/// @param section An index number identifying a section in tableView.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section){
        case 0:
            return BARCODE_DATA_VIEW_NUMBER_ROW_IN_SECTION_0;
        case 1:
            if ([barcodeList count] > 0){
                return [barcodeList count];
            }else{
                return BARCODE_DATA_VIEW_NUMBER_ROW_IN_SECTION_1_EMPTY_DATA;
            }
        default:
            return BARCODE_DATA_VIEW_NUMBER_ROW_IN_SECTION_DEFAULT;
    }
}

/// Asks the delegate for the height to use for a row in a specified location.
/// @param tableView The table view requesting this information.
/// @param indexPath An index path that locates a row in tableView.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (BARCODE_DATA_VIEW_DATA_SECTION_INDEX == [indexPath section]){
        /* barcode list section */
        if ([barcodeList count] > 0){
            return SCANNER_SETTINGS_BARCODE_CELL_HEIGHT;
        }else{
            return SCANNER_SETTINGS_DEFAULT_CELL_HEIGHT;
        }
    }else
    {
        return SCANNER_SETTINGS_DEFAULT_CELL_HEIGHT;
    }
}

/// Asks the data source for a cell to insert in a particular location of the table view. Required.
/// @param tableView A table-view object requesting the cell.
/// @param indexPath An index path locating a row in tableView.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    if (BARCODE_DATA_VIEW_ACTION_SECTION_INDEX == [indexPath section]){
    /* action section */
        static NSString *CellIdentifierAction = BARCODE_DATA_ACTION_CELL_ID;
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierAction forIndexPath:indexPath];
        
        switch ([indexPath row])
        {
            case 0:
                cell.textLabel.text = BARCODE_DATA_VIEW_PULL_TRIGGER;
                break;
            case 1:
                cell.textLabel.text = BARCODE_DATA_VIEW_RELEASE_TRIGGER;
                break;
            case 2:
                cell.textLabel.text = BARCODE_DATA_VIEW_SCAN;
                break;
            default:
                cell.textLabel.text = BARCODE_DATA_VIEW_UNKNOWN;
        }
    }else if (BARCODE_DATA_VIEW_DATA_SECTION_INDEX == [indexPath section]){
        /* barcode list section */
        if ([barcodeList count] > 0){
            static NSString *CellIdentifierData = BARCODE_DATA_VIEW_DATA_CELL_ID;
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierData forIndexPath:indexPath];
            
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifierData];
            }
           
            cell.textLabel.text = [(BarcodeData*)[barcodeList objectAtIndex:([barcodeList count] - 1 - [indexPath row])] getDecodeDataAsStringUsingEncoding:NSUTF8StringEncoding];
            
            cell.detailTextLabel.text = get_barcode_type_name([(BarcodeData*)[barcodeList objectAtIndex:([barcodeList count] - 1 - [indexPath row])] getDecodeType]);
   
        }else{
            static NSString *CellIdentifierNoData = BARCODE_DATA_VIEW_NO_DATA_CELL_ID;
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierNoData forIndexPath:indexPath];
            
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierNoData];
            }
            cell.textLabel.text = BARCODE_DATA_VIEW_NO_BARCODE_RECEIVED;
            cell.detailTextLabel.text = nil;
        }
    }
    
    
    return cell;
}


/// Asks the delegate for a view to display in the header of the specified section of the table view.
/// @param tableView The table view asking for the view.
/// @param section The index number of the section containing the header view.
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    /* Add custom section header for the Barcode list section in the table */
    if (BARCODE_DATA_VIEW_DATA_SECTION_INDEX == section)
    {
        /* Specify component sizes */
        CGFloat headerWidth = tableViewBarcode.frame.size.width;
        CGFloat headerHeight = BARCODE_DATA_VIEW_CLEAR_HEADER_HEIGHT;
        CGFloat btnWidth = BARCODE_DATA_VIEW_CLEAR_BUTTON_WIDTH;
        CGFloat btnHeight = BARCODE_DATA_VIEW_CLEAR_BUTTON_HEIGHT;
        
        /* Create custom view for section header */
        UITableViewHeaderFooterView *customHeaderView = [[[UITableViewHeaderFooterView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, headerWidth, headerHeight)] autorelease];
        
        /* Create clear button */
        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [clearButton setFrame:CGRectMake(headerWidth-btnWidth, 7.0f, btnWidth, btnHeight)];
        [clearButton setTitle:BARCODE_DATA_VIEW_CLEAR forState:UIControlStateNormal];
        [clearButton setBackgroundColor:[UIColor clearColor]];
        [clearButton addTarget:self action:@selector(btnClearBarcodeList:) forControlEvents:UIControlEventTouchUpInside];
        [customHeaderView addSubview:clearButton];
        
        [clearButton setEnabled:[barcodeList count] > 0 ? true : false];
        clearButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        if (@available(iOS 11, *)) {
          NSLayoutConstraint  *clearBtnConstraintRight = [NSLayoutConstraint constraintWithItem:clearButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:customHeaderView.safeAreaLayoutGuide attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-10];
             [customHeaderView addConstraint:clearBtnConstraintRight];
        } else {
           NSLayoutConstraint *clearBtnConstraintRight = [NSLayoutConstraint constraintWithItem:clearButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:customHeaderView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10];
             [customHeaderView addConstraint:clearBtnConstraintRight];
        }
        
        NSLayoutConstraint *clearBtnConstraintBottom = [NSLayoutConstraint constraintWithItem:clearButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:customHeaderView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        [customHeaderView addConstraint:clearBtnConstraintBottom];

        return customHeaderView;
    }
    return nil;
}


/// Asks the data source for the title of the header of the specified section of the table view.
/// @param tableView The table-view object asking for the title.
/// @param section An index number identifying a section of tableView
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (BARCODE_DATA_VIEW_ACTION_SECTION_INDEX == section)
    {
        return BARCODE_DATA_VIEW_ACTION_TITLE;
    }
    else if (BARCODE_DATA_VIEW_DATA_SECTION_INDEX == section)
    {
        return [NSString stringWithFormat:BARCODE_DATA_VIEW_BARCODE_LIST_WITH_COUNT_TITLE,(unsigned int)[barcodeList count]];
    }
    return BARCODE_DATA_VIEW_UNKNOWN;
}

#pragma mark - Table view delegate


/// Tells the delegate a row is selected.
/// @param tableView A table view informing the delegate about the new row selection.
/// @param indexPath An index path locating the new selected row in tableView.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (BARCODE_DATA_VIEW_ACTION_SECTION_INDEX == [indexPath section]) /* actions section */
    {
        switch ([indexPath row]) {
            case 0:
                activityView = [[zt_AlertView alloc] init];
                [activityView showAlertWithView:self.view withTarget:self withMethod:@selector(performActionTriggerPull) withObject:nil withString:nil];
                break;
            case 1:
                activityView = [[zt_AlertView alloc] init];
                [activityView showAlertWithView:self.view withTarget:self withMethod:@selector(performActionTriggerRelease) withObject:nil withString:nil];
                break;
            case 2:
                activityView = [[zt_AlertView alloc] init];
                [activityView showAlertWithView:self.view withTarget:self withMethod:@selector(performActionTriggerPull) withObject:nil withString:nil];
                break;
            default:
                // Not supported
                NSLog(@"ERROR: Switch to barcode mode is currently unsupported.");
                break;
        }
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell != nil)
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }else if (BARCODE_DATA_VIEW_DATA_SECTION_INDEX == [indexPath section]){
        if ([barcodeList count] > 0) {
            BarcodeData *selectedBarcodeData = [barcodeList objectAtIndex:([barcodeList count] - 1 - [indexPath row])];
            [[ScannerEngine sharedScannerEngine] setSelectedBarcodeValue:selectedBarcodeData];
        }
    }    
}

#pragma mark - Action clear

/// Clear table containing the scanned barcode list
/// @param sender id / button reference
- (IBAction)btnClearBarcodeList:(id)sender
{
    UIAlertController *popupMessageAlert = [UIAlertController alertControllerWithTitle:BARCODE_DATA_VIEW_ALERT_TITLE message:BARCODE_DATA_VIEW_ALERT_MESSAGE preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:BARCODE_DATA_VIEW_ALERT_CANCEL style:UIAlertActionStyleDefault handler:NULL];
    
    UIAlertAction *continueAction = [UIAlertAction actionWithTitle:BARCODE_DATA_VIEW_ALERT_CONTINUE style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
        [barcodeList removeAllObjects];
        [[ScannerEngine sharedScannerEngine] clearBarcodeData];
        [[ScannerEngine sharedScannerEngine] removeSelectedBarcodeValue];
        [tableViewBarcode reloadData];
    }];
    [popupMessageAlert addAction:cancelAction];
    [popupMessageAlert addAction:continueAction];
    [self presentViewController:popupMessageAlert animated:YES completion:nil];
}

- (void)dealloc
{
    if (barcodeList != nil)
    {
        [barcodeList removeAllObjects];
        [barcodeList release];
    }
    [tableViewBarcode release];
    [super dealloc];
}


/// Fetch the scanned barcode data using the barcode event.
/// @param barcodeData The scanned barcode data.
-(void)barcodeDataList:(NSData*)barcodeData barcodeType:(int)barcodeType
{
    NSLog(@"Barcode event recieved: %@ %d",barcodeData,barcodeType);
    [self showBarcodInTableView];
  
  
}

/// Show barcode in tableview
- (void)showBarcodInTableView
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        NSArray *temporyBarcodeList = [[ScannerEngine sharedScannerEngine] getScannerBarcodes];
        [barcodeList removeAllObjects];
        [barcodeList addObjectsFromArray:temporyBarcodeList];
        // update UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            UITableView *tableView = tableViewBarcode;
            if (tableView != nil)
            {
                /* show updated barcode list for this scanner */
                [tableView reloadData];
                
                /* scroll to top to show most recent barcode */
                [tableView setContentOffset:CGPointZero animated:YES];
            }
        });
        
    });
    
}


/// Perfrom Trigger Pull
- (void)performActionTriggerPull{
    SBT_RESULT res = [[ScannerEngine sharedScannerEngine] pullTiggerStart];
    
    if (res != SBT_RESULT_SUCCESS){
        dispatch_async(dispatch_get_main_queue(),^{
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:ZT_RFID_APP_NAME
                                         message:ZT_RFID_CANNOT_PERFORM_TRIGGER_PULL
                                         preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* okButton = [UIAlertAction
                                       actionWithTitle:OK
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                            /// Handle ok action
                                        }];
            [alert addAction:okButton];
            [self presentViewController:alert animated:YES completion:nil];
            [alert release];
        });
    }
}

/// Perfrom trigger release
- (void)performActionTriggerRelease{
    SBT_RESULT res = [[ScannerEngine sharedScannerEngine] releaseTiggerStart];
    
    if (res != SBT_RESULT_SUCCESS){
        dispatch_async(dispatch_get_main_queue(),^{
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:ZT_RFID_APP_NAME
                                         message:ZT_RFID_CANNOT_PERFORM_TRIGGER_RELEASE
                                         preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* okButton = [UIAlertAction
                                       actionWithTitle:OK
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                            /// Handle ok action
                                        }];
            [alert addAction:okButton];
            [self presentViewController:alert animated:YES completion:nil];
            [alert release];
        });
    }
}

/// Trigger rfid functionality
/// @param pressed if true is pressed
-(BOOL)onNewTriggerEvent:(BOOL)pressed typeRFID:(BOOL)isRFID{
    if (!isRFID){
        return YES;
    }
    __block BarcodeDataTableViewController *__weak_self = self;
    BOOL requested = [[[zt_RfidAppEngine sharedAppEngine] operationEngine] getStateInventoryRequested];
    
    if (YES == pressed){
        /* trigger press -> start operation if start trigger immediate */
        if (YES == [[[zt_RfidAppEngine sharedAppEngine] sledConfiguration] isStartTriggerImmediate]){
            /* immediate start trigger */
            if (NO == requested){
                /* operation is not in progress / requested */
                dispatch_async(dispatch_get_main_queue(),^{
                    [__weak_self triggerPress:nil];
                });
            }
        }
    }else{
        /* trigger release -> stop operation if stop trigger immediate */
        if (YES == [[[zt_RfidAppEngine sharedAppEngine] sledConfiguration] isStopTriggerImmediate]){
            /* immediate stop trigger */
            if (YES == requested){
                /* immediate stop trigger */
                if (YES == requested){
                    dispatch_async(dispatch_get_main_queue(),^{
                        [__weak_self triggerPress:nil];
                    });
                }
            }
        }
    }
    return YES;
}

/// Hard trigger function
/// @param sender sender's reference
- (IBAction)triggerPress:(id)sender{
    /// Clearing selected barcode value
    [[ScannerEngine sharedScannerEngine] removeSelectedBarcodeValue];
    [[[zt_RfidAppEngine sharedAppEngine] appConfiguration] removeAllMultiTagIds];
    NSString *statusMsg;
    if([[[zt_RfidAppEngine sharedAppEngine] operationEngine] getStateGetTagsOperationInProgress]){
        [self showWarning:BARCODE_RFID_IN_PROGRESS];
        return;
    }
    BOOL inventory_requested = [[[zt_RfidAppEngine sharedAppEngine] operationEngine] getStateInventoryRequested];
    SRFID_RESULT rfid_res = SRFID_RESULT_FAILURE;

    if (NO == inventory_requested){
        if ([[[zt_RfidAppEngine sharedAppEngine] sledConfiguration] isUniqueTagsReport] == [NSNumber numberWithBool:YES]){
            rfid_res = [[zt_RfidAppEngine sharedAppEngine] purgeTags:&statusMsg];
        }
        rfid_res = [[[zt_RfidAppEngine sharedAppEngine] operationEngine] startInventory:YES aMemoryBank:SRFID_MEMORYBANK_NONE message:&statusMsg];
        
    }else{
        rfid_res = [[[zt_RfidAppEngine sharedAppEngine] operationEngine] stopInventory:nil];
    }
}

/// Trigger event request
/// @param requested If true is requested
/// @param operation_type operation type of request
- (void)radioStateChangedOperationRequested:(BOOL)requested aType:(int)operation_type{
    if (ZT_RADIO_OPERATION_INVENTORY != operation_type){
        return;
    }
    
    if (YES == requested){
        /* clear selection information */
        [[[zt_RfidAppEngine sharedAppEngine] appConfiguration] clearTagIdAccessGracefully];
        [[[zt_RfidAppEngine sharedAppEngine] appConfiguration] clearTagIdLocationingGracefully];
        [[[zt_RfidAppEngine sharedAppEngine] appConfiguration] clearSelectedItem];
    }else{
        if([[[zt_RfidAppEngine sharedAppEngine] operationEngine] getStateGetTagsOperationInProgress]){
            NSString *statusMsg;
            [[[zt_RfidAppEngine sharedAppEngine] operationEngine] purgeTags:&statusMsg];
            if (![[[zt_RfidAppEngine sharedAppEngine] activeReader] isActive]){
                [[zt_RfidAppEngine sharedAppEngine] reconnectAfterBatchMode];
            }
        }
    }
}

/// Trigger event in progress
/// @param in_progress If true is requested
/// @param operation_type operation type of request
- (void)radioStateChangedOperationInProgress:(BOOL)in_progress aType:(int)operation_type{
    if (ZT_RADIO_OPERATION_INVENTORY != operation_type){
        return;
    }
}

/// Display message
/// @param message message
- (void)showWarning:(NSString *)message{
    [zt_AlertView showInfoMessage:self.view withHeader:ZT_RFID_APP_NAME withDetails:message withDuration:3];
}

@end
