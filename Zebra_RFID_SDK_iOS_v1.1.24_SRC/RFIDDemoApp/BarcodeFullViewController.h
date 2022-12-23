//
//  BarcodeFullViewController.h
//  RFIDDemoApp
//
//  Created by Sivarajah Pranavan on 2021-08-25.
//  Copyright © 2021 Zebra Technologies Corp. and/or its affiliates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BarcodeData.h"
#import "BarcodeTypes.h"

NS_ASSUME_NONNULL_BEGIN

/// Barcode detail view controller
@interface BarcodeFullViewController : UIViewController{
    BarcodeData *barcodeData;
    int scannerID;
    BOOL child;
    
    IBOutlet UILabel *labelScannerID;
    IBOutlet UILabel *labelBarcodeData;
    IBOutlet UILabel *labelBarcodeType;
}

- (void)setBarcodeEventData:(BarcodeData*)barcodeData fromScanner:(int)scannerID;
- (void)updateBarcodeUI;

@end

NS_ASSUME_NONNULL_END
