//
//  FactoryResetViewController.m
//  RFIDDemoApp
//
//  Created by Dhanushka Adrian on 2022-04-27.
//  Copyright © 2022 Zebra Technologies Corp. and/or its affiliates. All rights reserved. All rights reserved.
//

#import "FactoryResetViewController.h"
#import "UIColor+DarkModeExtension.h"
#import "RfidAppEngine.h"
#import "config.h"
#import "ui_config.h"

#define RADIO_SELECT_BUTTON     @"radio_button_icon_90"
#define RADIO_UNSELECT_BUTTON     @"radiobuttonoff_68"
#define FACTORY_RESET  @"Factory Reset"
#define REBOOT  @"Reboot"
#define IOS_VERSION 12.0
#define X_CORDINATE 0
#define Y_CORDINATE 0
#define BORDER_WIDTH 3.0f


@interface FactoryResetViewController ()

@end

/// Responsible for Reset and reboot the device
@implementation FactoryResetViewController

#pragma mark - Life Cycle Methods

/// Called after the controller's view is loaded into memory.
- (void)viewDidLoad {
    
    [super viewDidLoad];

}


/// Notifies the view controller that its view is about to be added to a view hierarchy.
/// @param animated If YES, the view is being added to the window using an animation.
-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    [self darkModeCheck:self.view.traitCollection];
    self.title = FACTORY_RESET;
    viewRebootFactoryResetPopup.layer.borderColor = [UIColor getDarkModeLabelTextColorForRapidRead:self.view.traitCollection].CGColor;
    viewRebootFactoryResetPopup.layer.borderWidth = BORDER_WIDTH;
    
}

#pragma mark - Change radio button image methods

/// Set  image color
/// @param traitCollection The traits, such as the size class and scale factor.
/// @param radioImageView The radio image view.
/// @param selectedImage The slected image.
-(void)setImageColor:(UITraitCollection *)traitCollection radioImageView:(UIImageView*)radioImageView radioImage:(UIImage*)selectedImage {
    
    UIImage *currentRadioImage = [radioImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIGraphicsBeginImageContextWithOptions(selectedImage.size, NO, currentRadioImage.scale);
    if (@available(iOS IOS_VERSION, *)) {
        if(traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark){
            [[UIColor whiteColor] set];
        }else{
            [[UIColor blackColor] set];
        }
    } else {
        [[UIColor blackColor] set];
    }
    [currentRadioImage drawInRect:CGRectMake(X_CORDINATE, Y_CORDINATE, selectedImage.size.width, currentRadioImage.size.height)];
    currentRadioImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    radioImageView.image = currentRadioImage;
    
}


/// Set radio image
/// @param traitCollection The traits, such as the size class and scale factor.
-(void)setRadioImage:(UITraitCollection *)traitCollection{
    
    selectedImage = [UIImage imageNamed:RADIO_SELECT_BUTTON];
    unselectedImage = [UIImage imageNamed:RADIO_UNSELECT_BUTTON];
    [self setImageColor:traitCollection radioImageView:imageReset radioImage:selectedImage];
    [self setImageColor:traitCollection radioImageView:imgesetReboot radioImage:unselectedImage];
    
}

#pragma mark - IBAction Methods

/// Factory reset  button action
/// @param sender id The button reference
-(IBAction) toggleUIButtonActionForReset:(id)sender {
    
    [self setRadioButton:NO];

 }

/// Reboot  button  action
/// @param sender id The button reference
-(IBAction) toggleUIButtonActionForReboot:(id)sender {
    
    [self setRadioButton:YES];
       
 }


/// Set radio button image and update button title
/// @param isReboot The status of reboot selection
-(void)setRadioButton:(BOOL)isRebootSelect {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        selectedImage = [UIImage imageNamed:RADIO_SELECT_BUTTON];
        unselectedImage = [UIImage imageNamed:RADIO_UNSELECT_BUTTON];

        if(isRebootSelect){
          imageReset.image = unselectedImage;
          imgesetReboot.image = selectedImage;
          [self setImageColor:self.view.traitCollection radioImageView:imageReset radioImage:unselectedImage];
          [self setImageColor:self.view.traitCollection radioImageView:imgesetReboot radioImage:selectedImage];
          [buttonResetReboot setTitle:REBOOT forState:UIControlStateNormal];
            
        }
        else {
            imageReset.image = selectedImage;
            imgesetReboot.image = unselectedImage;
            [self setImageColor:self.view.traitCollection radioImageView:imageReset radioImage:selectedImage];
            [self setImageColor:self.view.traitCollection radioImageView:imgesetReboot radioImage:unselectedImage];
            [buttonResetReboot setTitle:FACTORY_RESET forState:UIControlStateNormal];
        }
        
    });
    
}


/// Reboot and factory reset toggle button handle
/// @param sender The button reference
-(IBAction) toggleUIButtonActionForRebootAndFactoryReset:(id)sender {
    
    if([buttonResetReboot.titleLabel.text isEqual:REBOOT]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationController.navigationBar.userInteractionEnabled = NO;
            [viewRebootFactoryResetPopup setHidden:false];
        });
        // GCD
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
        // Compute big gnarly thing that would block for really long time.
            [self rebootDevice];
        });
    }
    
}

/// Reboot the device
-(void)rebootDevice {
    
        NSString *status = [[NSString alloc] init];
        SRFID_RESULT result = SRFID_RESULT_FAILURE;
        result = [[zt_RfidAppEngine sharedAppEngine] setReaderReboot:[[[zt_RfidAppEngine sharedAppEngine] activeReader] getReaderID] status:&status];
        
        if (result != SRFID_RESULT_FAILURE){
            dispatch_async(dispatch_get_main_queue(), ^{
                [viewRebootFactoryResetPopup setHidden:true];
                self.navigationController.navigationBar.userInteractionEnabled = YES;
                [self.navigationController popViewControllerAnimated:YES];
                
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlertMessageWithTitle:ZT_RFID_APP_NAME  withMessage:ZT_SCANNER_CANNOT_REBOOT_THE_DEVICE];
                self.navigationController.navigationBar.userInteractionEnabled = YES;
            });
        }
}

/// Display alert message
/// @param title Title string
/// @param messgae message string
-(void)showAlertMessageWithTitle:(NSString*)title withMessage:(NSString*)messgae{
    UIAlertController * alert = [UIAlertController
                    alertControllerWithTitle:title
                                     message:messgae
                              preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okButton = [UIAlertAction
                        actionWithTitle:OK
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //Handle ok action
                                }];
    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Dark mode handling

/// Check whether darkmode is changed
/// @param traitCollection The traits, such as the size class and scale factor.
-(void)darkModeCheck:(UITraitCollection *)traitCollection
{
    self.view.backgroundColor = [UIColor getDarkModeViewBackgroundColor:traitCollection];
    [self setRadioImage:traitCollection];
    viewRebootFactoryResetPopup.layer.borderColor = [UIColor getDarkModeLabelTextColorForRapidRead:self.view.traitCollection].CGColor;
    

}

/// Notifies the container that its trait collection changed.
/// @param traitCollection The traits, such as the size class and scale factor,.
/// @param coordinator The transition coordinator object managing the size change.
- (void)willTransitionToTraitCollection:(UITraitCollection *)traitCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    NSLog(@"Dark Mode change");
    [self darkModeCheck:traitCollection];
    self.view.backgroundColor = [UIColor getDarkModeViewBackgroundColor:traitCollection];
}


@end
