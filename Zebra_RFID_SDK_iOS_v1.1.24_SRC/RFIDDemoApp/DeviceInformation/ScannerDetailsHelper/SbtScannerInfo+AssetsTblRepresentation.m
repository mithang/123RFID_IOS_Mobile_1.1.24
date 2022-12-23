//
//  SbtScannerInfo+AssetsTblRepresentation.m
//  RFIDDemoApp
//
//  Created by Kasun Adhikari on 2021-11-17.
//  Copyright © 2021 Zebra Technologies Corp. and/or its affiliates. All rights reserved.

//

#import "SbtScannerInfo+AssetsTblRepresentation.h"
#import "SbtSdkDefs.h"
#import "ScannerEngine.h"
#import "RMDAttributes.h"
#import "config.h"
#import <objc/runtime.h>
#import "RFIDDemoAppDelegate.h"
#import "ui_config.h"
#import "config.h"
#import "RfidAppEngine.h"

NSString const *kPropertyKeyrsltsDic = @"kPropertyKeyrsltsDic";
NSString const *MODEL = @"Model Number:";
NSString const *SERIAL_NUMBER = @"Serial Number:";
NSString const *CONFIGURATION = @"Configuration:";
NSString const *FIRMWARE = @"Firmware:";
NSString const *MANUFACTURED_DATE = @"Manufacture Date:";
NSString const *RADIO_VERSION = @"RFIDRadio:";
NSString const *SCANNER_VERSION = @"Scanner Version:";

/// Assets information table representation
@implementation SbtScannerInfo (AssetsTblRepresentation)

@dynamic resultDictionary;

/// This method is to get asset details form the scanner
/// @param dictionary The dictionary object requesting the information.
- (NSMutableDictionary*)getAssetsTableRepresentation:(void (^)(NSMutableDictionary *dictionary))competionHnadler
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, queue, ^{
        [self getScannerInfo];
    });
    zt_SledConfiguration *sled = [[zt_RfidAppEngine sharedAppEngine] sledConfiguration];
    NSMutableDictionary *resultDataDictionary = @{SCANNER_ASSET_INFORMATION_TABLE_TITLES:@[MODEL, SERIAL_NUMBER, CONFIGURATION, FIRMWARE, RADIO_VERSION, MANUFACTURED_DATE, SCANNER_VERSION],
                                       SCANNER_ASSET_INFORMATION_TABLE_VALUES:@[[NSString stringWithFormat:DEVICE_INFORMATION_TYPE_FORMAT,self.scannerModelString == nil ? EMPTY_STRING:self.scannerModelString], self.serialNo == nil ? EMPTY_STRING:self.serialNo, [self getConfugurationType], sled.readerDeviceVersion == nil ? EMPTY_STRING:sled.readerDeviceVersion, sled.readerNGEVersion == nil ? EMPTY_STRING:sled.readerNGEVersion, self.mFD == nil ? EMPTY_STRING: self.mFD,
                                                                                sled.readerPL33 == nil ? EMPTY_STRING:sled.readerPL33]
                                       }.mutableCopy;
    
    [self setResultDictionary:resultDataDictionary];
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSMutableArray *temporaryArray = ((NSArray*)[[self getResultDictionary] valueForKey:SCANNER_ASSET_INFORMATION_TABLE_VALUES]).mutableCopy;
        if (self.scannerModelString) {
            temporaryArray[DEVICE_SCANNER_MODEL_INDEX_0] = self.scannerModelString;
        }
        if (self.serialNo) {
            temporaryArray[DEVICE_SCANNER_MODEL_INDEX_1] = self.serialNo;
        }
        if (sled.readerDeviceVersion) {
            temporaryArray[DEVICE_SCANNER_MODEL_INDEX_3] = sled.readerDeviceVersion;
        }
        
        if (sled.readerNGEVersion) {
            temporaryArray[DEVICE_SCANNER_MODEL_INDEX_4] = sled.readerNGEVersion;
        }
        if (self.mFD) {
            temporaryArray[DEVICE_SCANNER_MODEL_INDEX_5] = self.mFD;
        }
        if (sled.readerPL33) {
            temporaryArray[DEVICE_SCANNER_MODEL_INDEX_6] = sled.readerPL33;
        }
        [[self getResultDictionary] setValue:temporaryArray forKey:SCANNER_ASSET_INFORMATION_TABLE_VALUES];
        competionHnadler([self getResultDictionary]);
    });
    return [self getResultDictionary];
}

/// This method is to set asset details in to data dictionary
/// @param resultDictionary The resultDictionary object setting the asset information.
- (void)setResultDictionary:(NSMutableDictionary *)resultDictionary {
    objc_setAssociatedObject(self, (__bridge const void *)(kPropertyKeyrsltsDic), resultDictionary, OBJC_ASSOCIATION_RETAIN);
}

/// This method is to get asset details from the data dictionary
- (NSMutableDictionary*)getResultDictionary {
    return objc_getAssociatedObject(self, (__bridge const void *)(kPropertyKeyrsltsDic));
}

/// This method is to get device configuration type
- (NSString*)getConfugurationType {
    switch ([self getConnectionType])
    {
        case SBT_CONNTYPE_MFI:
            return SCANNER_ASSET_INFORMATION_DEVICE_CONFIGURATION_TYPE_MFI;
            break;
        case SBT_CONNTYPE_BTLE:
            return SCANNER_ASSET_INFORMATION_DEVICE_CONFIGURATION_TYPE_BTLE;
            break;
        default:
            return SCANNER_ASSET_INFORMATION_DEVICE_CONFIGURATION_TYPE_UNKNOWWN;
    }
}
/// This method is to get the connected scanner infomation 
- (void)getScannerInfo {
    NSString *in_xml = nil;
    
        SbtScannerInfo *scannerInformation = [[ScannerEngine sharedScannerEngine] getConnectedScannerInfo];
    
       int scannerID = scannerInformation.getScannerID;
    /**
     Model, MFD and serial no does not chage. So we need get the values for those variables only in the first time
     ***/
    if (!self.mFD || !self.serialNo || !self.scannerModelString) {
        in_xml = [NSString stringWithFormat:SCANNER_ASSET_INFORMATION_INXML_ALL, m_ScannerID, RMD_ATTR_FRMWR_VERSION, RMD_ATTR_MFD, RMD_ATTR_SERIAL_NUMBER, RMD_ATTR_MODEL_NUMBER];
    } else {
        in_xml = [NSString stringWithFormat:SCANNER_ASSET_INFORMATION_INXML_FIRMWARE_ONLY, m_ScannerID, RMD_ATTR_FRMWR_VERSION];
    }
    
    NSMutableString *result = [[NSMutableString alloc] init];
    [result setString:EMPTY_STRING];
    
   
    SBT_RESULT res = [[ScannerEngine sharedScannerEngine]  executeCommand:SBT_RSM_ATTR_GET aInXML:in_xml aOutXML:result forScanner:scannerID];
    
    if (SBT_RESULT_SUCCESS != res) {
        [self assetInformationNotReceivedAlert];
    }
    
    BOOL success = FALSE;
    
    do {
        NSString* responseString = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSString* temporaryTag = SCANNER_ASSET_INFORMATION_ATTRIBUTE_START;
        NSRange range = [responseString rangeOfString:temporaryTag];
        NSRange attributeRange;
        
        if ((range.location == NSNotFound) || (range.length != [temporaryTag length]))
        {
            break;
        }
        
        responseString = [responseString substringFromIndex:(range.location + range.length)];
        
        temporaryTag = SCANNER_ASSET_INFORMATION_ATTRIBUTE_END;
        range = [responseString rangeOfString:temporaryTag];
        
        if ((range.location == NSNotFound) || (range.length != [temporaryTag length]))
        {
            break;
        }
        
        range.length = [responseString length] - range.location;
        
        responseString = [responseString stringByReplacingCharactersInRange:range withString:EMPTY_STRING];
        
        NSArray *responseAttributeString = [responseString componentsSeparatedByString:SCANNER_ASSET_INFORMATION_ATTRIBUTE_TAG];
        
        if ([responseAttributeString count] == 0)
        {
            break;
        }
        
        NSString *attributeString;
        
        int attributeId;
        int attributeValue;
        
        for (NSString *tagValueString in responseAttributeString)
        {
            attributeString = tagValueString;
            
            temporaryTag = SCANNER_ASSET_INFORMATION_ID_START_TAG;
            range = [attributeString rangeOfString:temporaryTag];
            if ((range.location != 0) || (range.length != [temporaryTag length]))
            {
                break;
            }
            attributeString = [attributeString stringByReplacingCharactersInRange:range withString:EMPTY_STRING];
            
            temporaryTag = SCANNER_ASSET_INFORMATION_ID_END_TAG;
            
            range = [attributeString rangeOfString:temporaryTag];
            
            if ((range.location == NSNotFound) || (range.length != [temporaryTag length]))
            {
                break;
            }
            
            attributeRange.length = [attributeString length] - range.location;
            attributeRange.location = range.location;
            
            NSString *attributeIdString = [attributeString stringByReplacingCharactersInRange:attributeRange withString:EMPTY_STRING];
            
            attributeId = [attributeIdString intValue];
            
            
            attributeRange.location = 0;
            attributeRange.length = range.location + range.length;
            
            attributeString = [attributeString stringByReplacingCharactersInRange:attributeRange withString:EMPTY_STRING];
            
            temporaryTag = SCANNER_ASSET_INFORMATION_VALUE_START_TAG;
            range = [attributeString rangeOfString:temporaryTag];
            if ((range.location == NSNotFound) || (range.length != [temporaryTag length]))
            {
                break;
            }
            attributeString = [attributeString substringFromIndex:(range.location + range.length)];
            
            temporaryTag = SCANNER_ASSET_INFORMATION_VALUE_END_TAG;
            
            range = [attributeString rangeOfString:temporaryTag];
            
            if ((range.location == NSNotFound) || (range.length != [temporaryTag length]))
            {
                break;
            }
            
            range.length = [attributeString length] - range.location;
            
            attributeString = [attributeString stringByReplacingCharactersInRange:range withString:EMPTY_STRING];
            
            attributeValue = [attributeString intValue];
            
            if (RMD_ATTR_FRMWR_VERSION == attributeId)
            {
                self.firmwareVersion = attributeString;
            }
            else if (RMD_ATTR_MFD == attributeId)
            {
                self.mFD = attributeString;
            } else if (RMD_ATTR_SERIAL_NUMBER == attributeId)
            {
                self.serialNo = attributeString;
            } else if(RMD_ATTR_MODEL_NUMBER == attributeId) {
                self.scannerModelString = attributeString;
            }
            else
            {
                break;
            }
        }
        
        success = TRUE;
        
    } while (0);
    
    if (FALSE == success)
    {
        [self showErrorAlert];
    }
    
}

/// This method is to show alert dialog
-(void)showErrorAlert{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
        UIAlertController * alert = [UIAlertController
                        alertControllerWithTitle:ZT_RFID_APP_NAME
                                         message:ZT_SCANNER_ERROR_MESSAGE
                                  preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okButton = [UIAlertAction
                            actionWithTitle:OK
                                      style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        //Handle ok action
                                    }];
        [alert addAction:okButton];

        zt_RfidDemoAppDelegate *appDelegate = (zt_RfidDemoAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
                   }
                   );
    return;
}

/// This method is to show alert dialog when asset information are not available
-(void)assetInformationNotReceivedAlert{
    
    dispatch_async(dispatch_get_main_queue(),
                   ^{
        UIAlertController * alert = [UIAlertController
                        alertControllerWithTitle:ZT_RFID_APP_NAME
                                         message:ZT_SCANNER_CANNOT_RETRIEVE_ASSET_MESSAGE
                                  preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okButton = [UIAlertAction
                            actionWithTitle:OK
                                      style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        //Handle ok action
                                    }];
        [alert addAction:okButton];
        zt_RfidDemoAppDelegate *appDelegate = (zt_RfidDemoAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
                    
                    }
                   );
    return;
}
@end
