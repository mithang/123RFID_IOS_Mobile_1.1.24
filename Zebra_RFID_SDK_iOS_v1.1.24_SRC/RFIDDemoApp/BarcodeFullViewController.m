//
//  BarcodeFullViewController.m
//  RFIDDemoApp
//
//  Created by Sivarajah Pranavan on 2021-08-25.
//  Copyright © 2021 Zebra Technologies Corp. and/or its affiliates. All rights reserved.
//

#import "BarcodeFullViewController.h"
#import "ui_config.h"
#import "ScannerEngine.h"

@interface BarcodeFullViewController ()

@end

/// Barcode detail view controller
@implementation BarcodeFullViewController

/* default cstr for storyboard */
/// Returns an object initialized from data in a given unarchiver.
/// @param aDecoder An unarchiver object.
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil)
    {
        child = NO;
        scannerID = SBT_SCANNER_ID_INVALID;
    }
    return self;
}

/// Deallocates the memory occupied by the receiver.
- (void)dealloc
{
    [labelScannerID release];
    [labelBarcodeType release];
    [labelBarcodeData release];
    [super dealloc];
}

/// Called after the controller's view is loaded into memory.
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = BARCODE_FULL_VIEW_TITLE;
}

/// Notifies the view controller that its view is about to be added to a view hierarchy.
/// @param animated If YES, the view is being added to the window using an animation.
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateBarcodeUI];
}


/// Notifies the view controller that its view was added to a view hierarchy.
/// @param animated If YES, the view was added to the window using an animation.
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateBarcodeUI];
}

/// Called to notify the view controller that its view has just laid out its subviews.
- (void)viewDidLayoutSubviews
{
    dispatch_async(dispatch_get_main_queue(), ^{
        labelBarcodeData.preferredMaxLayoutWidth = labelBarcodeData.bounds.size.width;
    });
}


/// Sent to the view controller when the app receives a memory warning.
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/// Set barcode data from barcode parent screen
/// @param barcodeData barcode data object
/// @param scannerID scanner's id
- (void)setBarcodeEventData:(BarcodeData*)barcodeData fromScanner:(int)scannerID
{
    scannerID = scannerID;
    barcodeData = barcodeData;
    [self updateBarcodeUI];
}


/// Update ui with barcode data
- (void)updateBarcodeUI
{
    [labelScannerID setText:[NSString stringWithFormat:BARCODE_FULL_VIEW_SCANNER_ID_FORMAT, scannerID]];
    [labelBarcodeType setText:[NSString stringWithFormat:BARCODE_FULL_VIEW_BARCODE_TYPE_FORMAT, get_barcode_type_name([barcodeData getDecodeType])]];
    [labelBarcodeData setText:[barcodeData getDecodeDataAsStringUsingEncoding:NSUTF8StringEncoding]];
}

@end
