//
//  ProfilesViewController.m
//  RFIDDemoApp
//
//  Created by Symbol on 05/01/21.
//  Copyright © 2021 Zebra Technologies Corp. and/or its affiliates. All rights reserved.
//

#import "ProfilesViewController.h"
#import "ui_config.h"
#import "ProfileTableViewCell.h"
#import "RfidAppEngine.h"
#import "UIColor+DarkModeExtension.h"
#import "LinkProfileObject.h"

#define ZD_PROFILE_CELL                         @"ID_PROFILE_CELL"
#define ZT_CELL_HEIGHT_PROFILE_CELL             50
#define ZT_CELL_EXP_HEIGHT_PROFILE_CELL         260
#define ZT_CELL_EXP_HEIGHT_NEW_PROFILE_CELL     270

#define INVENTORY_STATE_AB_FLIP     2
#define INVENTORY_STATE_STATE_A     0
#define FAST_READ_PROFILE    0
#define DEFAULT_RESPONSE_MESSAGE    @""

@interface zt_ProfilesViewController ()<UITextFieldDelegate>
{
    NSIndexPath * selectedIndex;
    IBOutlet UIView * pickerBgView;
    IBOutlet UIPickerView * pickerView;
    IBOutlet UIButton * closeButton;
    NSString * pickerType;
    NSString * activeProfile;
    NSInteger selectedSessionIndex;
    NSInteger selectedLinkIndex;
}
@property (nonatomic) NSArray *sessionChoices;
@property (nonatomic) NSArray *linkChoices;
@property (nonatomic) NSDictionary * fastReadDic;
@property (nonatomic) NSDictionary * cycleCountDic;
@property (nonatomic) NSDictionary * denseReadDic;
@property (nonatomic) NSDictionary * optimalBatDic;
@property (nonatomic) NSDictionary * balPerDic;
@property (nonatomic) NSDictionary * userDefinedDic;
@property (nonatomic) NSDictionary * readerDefinedDic;
@end

/// The UIViewController class defines the shared behavior that is common to all view controllers.
@implementation zt_ProfilesViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil)
    {
        _fastReadDic = @{PROFILE_KEY_CONTENT:PROFILE_FASTEST_READ,PROFILE_KEY_DETAILS:FASTEST_READ_SUB_TITLE,PROFILE_KEY_POWER:POWER_LEVEL_VALUE1,PROFILE_KEY_LINKPROFILE:@1,PROFILE_KEY_SESSION:@0,PROFILE_KEY_DYNAMICPOWER:@0};
        _cycleCountDic = @{PROFILE_KEY_CONTENT:PROFILE_CYCLE_COUNT,PROFILE_KEY_DETAILS:CYCLE_COUNT_SUB_TITLE,PROFILE_KEY_POWER:POWER_LEVEL_VALUE1,PROFILE_KEY_LINKPROFILE:@0,PROFILE_KEY_SESSION:@2,PROFILE_KEY_DYNAMICPOWER:@0};
        _denseReadDic = @{PROFILE_KEY_CONTENT:PROFILE_DENSE_READERS,PROFILE_KEY_DETAILS:DENSE_READERS_SUB_TITLE,PROFILE_KEY_POWER:POWER_LEVEL_VALUE1,PROFILE_KEY_LINKPROFILE:@5,PROFILE_KEY_SESSION:@1,PROFILE_KEY_DYNAMICPOWER:@0};
        _optimalBatDic = @{PROFILE_KEY_CONTENT:PROFILE_OPTIMAL_BATTERY,PROFILE_KEY_DETAILS:OPTIMAL_BATTERY_SUB_TITLE,PROFILE_KEY_POWER:POWER_LEVEL_VALUE2,PROFILE_KEY_LINKPROFILE:@0,PROFILE_KEY_SESSION:@1,PROFILE_KEY_DYNAMICPOWER:@1};
        _balPerDic = @{PROFILE_KEY_CONTENT:PROFILE_BALANCED_PERFORMANCE,PROFILE_KEY_DETAILS:BALANCED_PERFORMANCE_SUB_TITLE,PROFILE_KEY_POWER:POWER_LEVEL_VALUE3,PROFILE_KEY_LINKPROFILE:@0,PROFILE_KEY_SESSION:@1,PROFILE_KEY_DYNAMICPOWER:@1};
        _userDefinedDic = @{PROFILE_KEY_CONTENT:PROFILE_USER_DEFINED,PROFILE_KEY_DETAILS:USER_DEFINED_SUB_TITLE,PROFILE_KEY_POWER:POWER_LEVEL_VALUE3,PROFILE_KEY_LINKPROFILE:@0,PROFILE_KEY_SESSION:@1,PROFILE_KEY_DYNAMICPOWER:@1};
        _readerDefinedDic = @{PROFILE_KEY_CONTENT:PROFILE_READER_DEFINED,PROFILE_KEY_DETAILS:READER_DEFINED_SUB_TITLE,PROFILE_KEY_POWER:POWER_LEVEL_VALUE3,PROFILE_KEY_LINKPROFILE:@0,PROFILE_KEY_SESSION:@1,PROFILE_KEY_DYNAMICPOWER:@1};
        m_profileDetails_list = [[NSMutableArray alloc] initWithObjects:_fastReadDic,_cycleCountDic,_denseReadDic,_optimalBatDic,_balPerDic,_userDefinedDic,_readerDefinedDic, nil];
    }
    return self;
}

- (void)dealloc
{
    if (nil != _sessionChoices)
    {
        [_sessionChoices release];
    }
    if (nil != _linkChoices)
    {
        [_linkChoices release];
    }
    
    [profile_table release];
    [super dealloc];
}

#pragma mark - Life cycle methods
/// Called after the controller's view is loaded into memory.
- (void)viewDidLoad {
    [profile_table setDelegate:self];
    [profile_table setDataSource:self];
    [self setTitle:PROFILE_TITLE];
    expanded = false;
    activeProfile = 0;
    selectedSessionIndex = 0;
    selectedLinkIndex = 0;
    [self setupConfigurationInitial];
    [pickerBgView setHidden:YES];
    [self.view sendSubviewToBack:pickerBgView];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:PROFILE_DEFAULTS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [super viewDidLoad];
}

/// Notifies the view controller that its view is about to be added to a view hierarchy.
/// @param animated If true, the view is being added to the window using an animation.
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    inventoryRequested = [[[zt_RfidAppEngine sharedAppEngine] operationEngine] getStateInventoryRequested];
    
    if (inventoryRequested == NO) {
        self.view.userInteractionEnabled = YES;
        profile_table.userInteractionEnabled = YES;
    }else
    {
        self.view.userInteractionEnabled = NO;
        profile_table.userInteractionEnabled = NO;
    }
}

/// Notifies the view controller that its view was added to a view hierarchy.
/// @param animated If true, the view was added to the window using an animation.
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self darkModeCheck:self.view.traitCollection];
}


/// Notifies the view controller that its view was removed from a view hierarchy.
/// @param animated If true, the disappearance of the view was animated.
- (void)viewDidDisappear:(BOOL)animated {
    
    [self saveDynamicPower];
    [self saveAntennaSettings];
    [self saveSingulationConfig];
    [super viewDidDisappear:animated];
}

/// To setting up the sled configuration
- (void)setupConfigurationInitial
{
    /* TBD: configure based on app / reader settings */
    zt_SledConfiguration *localconfiguration = [[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy];
    _sessionChoices = [[localconfiguration.mapperSession getStringArray] mutableCopy];
    _linkChoices = [[localconfiguration getLinkProfileArray] mutableCopy];
    
    BOOL userDefined = [[NSUserDefaults standardUserDefaults] boolForKey:ANTENNA_DEFAULTS_KEY];
    
    if (userDefined) {
        activeProfile = [[NSUserDefaults standardUserDefaults] valueForKey:DEFAULTS_KEY];
        if ([activeProfile  isEqual: READER_DEFINED_INDEX]) {
            [self updateActiveProfile:activeProfile];
        }else
        {
            activeProfile = USER_DEFINED_INDEX;
            [self updateActiveProfile:activeProfile];
        }
        
    }else
    {
        activeProfile = [[NSUserDefaults standardUserDefaults] valueForKey:DEFAULTS_KEY];
        [self updateActiveProfile:activeProfile];
    }
}

/// Fetch the profile name using the index from linkprofiles array.
/// @param profileIndex The profile index from the linkprofile object.
/// @param linkProfilesArray The linkprofiles array to fetch matching index.
-(NSString *)getMatchingProfileNameByIndex:(int)profileIndex linkProfileArray:(NSMutableArray*) linkProfilesArray{
    
    NSString * profileName = @"";
    
    for (zt_LinkProfileObject *linkProfileObject in linkProfilesArray) {
        
        NSLog(@" Profile %@",linkProfileObject.legacyProfileName);
        if ([linkProfileObject.modeTableEntry getRFModeIndex] == profileIndex){
            
            profileName = [linkProfileObject getProfile];
            break;
        }
    }
    return profileName;
}

/* ###################################################################### */
/* ########## Text Field Delegate Protocol implementation ############### */
/* ###################################################################### */

/// Asks the delegate whether to process the pressing of the Return button for the text field.
/// @param textField The text field whose return button was pressed.
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    /* just to hide keyboard */
    [textField resignFirstResponder];
    return YES;
}

/// Tells the delegate when editing begins in the specified text field.
/// @param textField The text field in which an editing session began.
- (void) textFieldDidBeginEditing:(UITextField *)textField {
    zt_ProfileTableViewCell *cell;
    cell = (zt_ProfileTableViewCell *) textField.superview.superview.superview;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(TOP, LEFT, BOTTOM, RIGHT);
    profile_table.contentInset = contentInsets;
    profile_table.scrollIndicatorInsets = contentInsets;

    [profile_table scrollToRowAtIndexPath:[profile_table indexPathForCell:cell] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

/// Tells the delegate when editing stops for the specified text field.
/// @param textField The text field for which editing ended.
- (void) textFieldDidEndEditing:(UITextField *)textField
{
    profile_table.contentInset = UIEdgeInsetsZero;
    profile_table.scrollIndicatorInsets = UIEdgeInsetsZero;
    zt_SledConfiguration *configuration = [[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy];
    NSString * floatString = textField.text;
    configuration.currentAntennaPowerLevel = [floatString floatValue];
    activeProfile = [NSString stringWithFormat:@"%ld",(long)[textField tag]];
    [[NSUserDefaults standardUserDefaults] setValue:activeProfile forKey:DEFAULTS_KEY];
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:ANTENNA_DEFAULTS_KEY];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:PROFILE_DEFAULTS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setupConfigurationInitial];
}

#pragma mark - Table view data source

/// Asks the data source to return the number of sections in the table view.
/// @param tableView An object representing the table view requesting this information.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return NO_OF_SECTION_IN_PROFILES;
    
}


/// Returns the number of rows (table cells) in a specified section.
/// @param tableView An object representing the table view requesting this information.
/// @param section An index number that identifies a section of the table. Table views in a plain style have a section index of zero.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return NO_OF_ROW_IN_PROFILES;
}

/// To set the height for row at indexpath in the tableview which is using to show the available readers in the scan and pair screen.
/// @param tableView This tableview is used to show the available readers list in the scan and pair screen.
/// @param indexPath Here we are getting the current indexpath of the item to set proper height to the cell.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (expanded && indexPath == selectedIndex) {
        switch (indexPath.row) {
            case 4:
                return ZT_CELL_EXP_HEIGHT_NEW_PROFILE_CELL;
                break;
            case 6:
                return ZT_CELL_EXP_HEIGHT_NEW_PROFILE_CELL;
                break;
            default:
                return ZT_CELL_EXP_HEIGHT_PROFILE_CELL;
                break;
        }
    }else{
        return ZT_CELL_HEIGHT_PROFILE_CELL;
    }
}

/// To set the cell for row at indexpath in the tableview which is using to show the available readers in the scan and pair screen.
/// @param tableView This tableview is used to show the available readers list in the scan and pair screen.
/// @param indexPath Here we are getting the current indexpath of the item to show the proper values in the cell.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    zt_ProfileTableViewCell * profile_cell = [profile_table dequeueReusableCellWithIdentifier:ZD_PROFILE_CELL];
    
    NSString * title = [[m_profileDetails_list objectAtIndex:indexPath.row] objectForKey:PROFILE_KEY_CONTENT];
    NSString * sub_title = [[m_profileDetails_list objectAtIndex:indexPath.row] objectForKey:PROFILE_KEY_DETAILS];
    NSString * power_level = [[m_profileDetails_list objectAtIndex:indexPath.row] objectForKey:PROFILE_KEY_POWER];
    NSString * link_profile = [[m_profileDetails_list objectAtIndex:indexPath.row] objectForKey:PROFILE_KEY_LINKPROFILE];
    NSString * session = [[m_profileDetails_list objectAtIndex:indexPath.row] objectForKey:PROFILE_KEY_SESSION];
    BOOL dynamic = [[[m_profileDetails_list objectAtIndex:indexPath.row] objectForKey:PROFILE_KEY_DYNAMICPOWER] boolValue];
    BOOL isActive = false;
    if (indexPath.row == [activeProfile intValue]) {
        isActive = true;
    }else
    {
        isActive = false;
    }
    
    if ([_linkChoices count] != 0 && [_sessionChoices count] != 0 && [_linkChoices count] > [link_profile intValue] && [_sessionChoices count] > [session intValue]) {
        [profile_cell setCellInformation:title withsubtitle:sub_title powerLevel:power_level linkProfile:[_linkChoices objectAtIndex:[link_profile intValue]] session:[_sessionChoices objectAtIndex:[session intValue]] dynamicPower:dynamic isActive:isActive isExpanded:expanded];
    }
    
    if (expanded && indexPath == selectedIndex) {
        [profile_cell.selectionSwitch setHidden:false];
        [profile_cell.selectionSwitch addTarget:self action:@selector(profileSwitchToggled:) forControlEvents:UIControlEventTouchUpInside];
        profile_cell.selectionSwitch.tag = indexPath.row;
    }else{
        [profile_cell.selectionSwitch setHidden:true];
        
    }
    [profile_cell.linkProfileBtn setTag:indexPath.row];
    [profile_cell.sessionBtn setTag:indexPath.row];
    [profile_cell.fieldPowerLevel setTag:indexPath.row];
    [profile_cell.switchDynamicPower setTag:indexPath.row];
    profile_cell.fieldPowerLevel.delegate = self;
    [profile_cell.switchDynamicPower addTarget:self action:@selector(dynamicSwitchToggled:) forControlEvents:UIControlEventTouchUpInside];
    [profile_cell.linkProfileBtn addTarget:self action:@selector(linkBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [profile_cell.sessionBtn addTarget:self action:@selector(sessionBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    profile_cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [profile_cell darkModeCheck:self.view.traitCollection];
    return profile_cell;
}

/// Tells the delegate a row is selected.
/// @param tableView An object representing the table view requesting this information.
/// @param indexPath An index path locating the new selected row in tableView.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (selectedIndex == indexPath && expanded) {
        expanded = false;
    }else {
        expanded = true;
    }
    selectedIndex = indexPath;
    [tableView reloadData];
}

/// A control that offers a binary choice, such as on/off.
/// @param sender We can pass the any uicomponent as a sender.
- (void) profileSwitchToggled:(id)sender
{
    if ([sender isOn]) {
        activeProfile = [NSString stringWithFormat:@"%ld",(long)[sender tag]];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:PROFILE_DEFAULTS_KEY];
    }else
    {
        activeProfile = 0;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:PROFILE_DEFAULTS_KEY];
    }
    [[NSUserDefaults standardUserDefaults] setValue:activeProfile forKey:DEFAULTS_KEY];
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:ANTENNA_DEFAULTS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self updateActiveProfile:activeProfile];
    
}

/// An opaque type that represents a method in a class definition.
/// @param activeIndex Send the active profile index selected by the user
- (void) updateActiveProfile:(NSString *)activeIndex;
{
    zt_SledConfiguration *localSledConfiguration = [[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy];
    zt_SledConfiguration *sledConfiguration = [[zt_RfidAppEngine sharedAppEngine] sledConfiguration];

    
    if ([activeIndex intValue] < 5) {
        NSDictionary * activeProfileDic = [m_profileDetails_list objectAtIndex:[activeIndex integerValue]];
        NSString * powerLevel = [activeProfileDic objectForKey:PROFILE_KEY_POWER];
        NSNumber * linkProfileKey = [activeProfileDic objectForKey:PROFILE_KEY_LINKPROFILE];
        int linkProfileIndex = [linkProfileKey intValue];
        selectedLinkIndex = linkProfileIndex;
        NSString *linkProfileindexValue = @(linkProfileIndex).stringValue;
        NSString * profileName = [_linkChoices objectAtIndex:linkProfileIndex];
            
        NSNumber * sessionKey = [activeProfileDic objectForKey:PROFILE_KEY_SESSION];
        int sessionIndex = [sessionKey intValue];
        selectedSessionIndex = sessionIndex;
        NSNumber * dynamicProfileKey = [activeProfileDic objectForKey:PROFILE_KEY_DYNAMICPOWER];
        [self updateUserDefinedProfileFromActiveProfile:powerLevel linkProfileIndex:linkProfileindexValue sessionIndex:sessionKey dynamicProfile:dynamicProfileKey];
        localSledConfiguration.currentAntennaPowerLevel = [powerLevel floatValue];
        [self setLinkProfileIndex:profileName];
        localSledConfiguration.currentSession = [localSledConfiguration.mapperSession getEnumByIndx:sessionIndex];
        localSledConfiguration.currentDpoEnable = dynamicProfileKey;
        sledConfiguration.currentDpoEnable = dynamicProfileKey;
       
        if([activeIndex intValue] == FAST_READ_PROFILE) {
            localSledConfiguration.currentInventoryState = INVENTORY_STATE_AB_FLIP;
        }else{
            localSledConfiguration.currentInventoryState = INVENTORY_STATE_STATE_A;
        }
        
    }else
    {
        SRFID_SESSION session_selected = localSledConfiguration.currentSession;

        NSNumber *sessionIndex = [NSNumber numberWithInt:(int)[_sessionChoices indexOfObject:[localSledConfiguration.mapperSession getStringByEnum:session_selected]]];

        selectedSessionIndex = [sessionIndex integerValue];

        NSString *powerLevelKey = [@(localSledConfiguration.currentAntennaPowerLevel) stringValue];
        NSNumber *linkProfileKey = [NSNumber numberWithInt:localSledConfiguration.currentAntennaLinkProfile];
        int linkProfileIndex = [linkProfileKey intValue];
        NSString * profileName = [self getMatchingProfileNameByIndex:linkProfileIndex linkProfileArray:localSledConfiguration.linkProfilesArray];
        
        NSNumber *dynamicProfileKey = [localSledConfiguration currentDpoEnable];
        NSString *linkProfileindexValue = [NSString stringWithFormat:@"%lu",(unsigned long)[_linkChoices indexOfObject:profileName]];
        selectedLinkIndex = [linkProfileindexValue intValue];
        [self updateUserDefinedProfileFromActiveProfile:powerLevelKey linkProfileIndex:linkProfileindexValue sessionIndex:sessionIndex dynamicProfile:dynamicProfileKey];
        localSledConfiguration.currentAntennaPowerLevel = [powerLevelKey floatValue];
        [self setLinkProfileIndex:profileName];
        localSledConfiguration.currentSession = [localSledConfiguration.mapperSession getEnumByIndx:[sessionIndex intValue]];
        localSledConfiguration.currentDpoEnable = dynamicProfileKey;
        sledConfiguration.currentDpoEnable = dynamicProfileKey;
    }
    
}

/// Save dynamic power settings
-(void)saveDynamicPower {
    
    @try {
    
        SRFID_RESULT resultForDynamicPowerSettings = SRFID_RESULT_FAILURE;
        NSString *responseForDynamicPowerSettings = DEFAULT_RESPONSE_MESSAGE;
        resultForDynamicPowerSettings = [[zt_RfidAppEngine sharedAppEngine] setDpoConfigurationFromLocal:&responseForDynamicPowerSettings];
        [self handleCommandResult:resultForDynamicPowerSettings withStatusMessage:responseForDynamicPowerSettings];
 
     }
     @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
    }
    
}

/// Save singulation  config
-(void)saveSingulationConfig {
   
    @try {
       
        SRFID_RESULT resultForSingulationSettings = SRFID_RESULT_FAILURE;
        NSString *responseForSingulationSettings = DEFAULT_RESPONSE_MESSAGE;
        resultForSingulationSettings = [[zt_RfidAppEngine sharedAppEngine] setSingulationConfigurationFromLocal:&responseForSingulationSettings];
        [self handleCommandResult:resultForSingulationSettings withStatusMessage:responseForSingulationSettings];
    
     }
     @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
       
     }
    
}

/// Save antenna  settings
-(void)saveAntennaSettings {

    @try {
      
        SRFID_RESULT resultForAntennaConfigure = SRFID_RESULT_FAILURE;
        NSString *responseForAntennaConfigure = DEFAULT_RESPONSE_MESSAGE;
        resultForAntennaConfigure = [[zt_RfidAppEngine sharedAppEngine] setAntennaConfigurationFromLocal:&responseForAntennaConfigure];
        [self handleCommandResult:resultForAntennaConfigure withStatusMessage:responseForAntennaConfigure];
    }
    @catch (NSException *exception) {
       NSLog(@"%@", exception.reason);
    }
}


/// Handle the command result
/// @param result result  The result
/// @param message The message
- (void)handleCommandResult:(SRFID_RESULT)result withStatusMessage:(NSString *)message
{
    switch (result) {
        case SRFID_RESULT_SUCCESS:
            NSLog(@"Sucess");
            break;
            
        case SRFID_RESULT_FAILURE:
            NSLog(@"Failed");
            break;
            
        case SRFID_RESULT_RESPONSE_ERROR:
            NSLog(@"Response error");
            break;
            
        case SRFID_RESULT_RESPONSE_TIMEOUT:
            NSLog(@" Time out");
            break;
            
        default:
            break;
    }
}

/// To update the user defined and reader defined profiles using the active profile.
/// @param powerLevelKey The updated power level from the array.
/// @param linkProfileIndexValue The selected link profile index value from the array.
/// @param sessionIndex The selected session index from the array.
/// @param dynamicProfileKey The updated dynamic key from the array.
- (void) updateUserDefinedProfileFromActiveProfile:(NSString *)powerLevelKey linkProfileIndex:(NSString *) linkProfileIndexValue sessionIndex:(NSNumber *)sessionIndex dynamicProfile:(NSNumber *) dynamicProfileKey
{
    NSDictionary * tempUserDic = @{PROFILE_KEY_CONTENT:PROFILE_USER_DEFINED,PROFILE_KEY_DETAILS:USER_DEFINED_SUB_TITLE,PROFILE_KEY_POWER:powerLevelKey,PROFILE_KEY_LINKPROFILE:linkProfileIndexValue,PROFILE_KEY_SESSION:sessionIndex,PROFILE_KEY_DYNAMICPOWER:dynamicProfileKey};
    _userDefinedDic = tempUserDic;
    [m_profileDetails_list removeObjectAtIndex:5];
    [m_profileDetails_list insertObject:_userDefinedDic atIndex:5];
    NSDictionary * tempReaderDic = @{PROFILE_KEY_CONTENT:PROFILE_READER_DEFINED,PROFILE_KEY_DETAILS:READER_DEFINED_SUB_TITLE,PROFILE_KEY_POWER:powerLevelKey,PROFILE_KEY_LINKPROFILE:linkProfileIndexValue,PROFILE_KEY_SESSION:sessionIndex,PROFILE_KEY_DYNAMICPOWER:dynamicProfileKey};
    _readerDefinedDic = tempReaderDic;
    [m_profileDetails_list removeObjectAtIndex:6];
    [m_profileDetails_list insertObject:_readerDefinedDic atIndex:6];
    [profile_table reloadData];
}

/// Adding the action for the uiswitch to perform the operation
/// @param sender We can pass the any uicomponent as a sender.
- (void) dynamicSwitchToggled:(id)sender
{
    if ([sender isOn]) {
        enabled = true;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:PROFILE_DEFAULTS_KEY];
    }else
    {
        enabled = false;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:PROFILE_DEFAULTS_KEY];
    }
    zt_SledConfiguration *localSledConfiguration = [[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy];
    zt_SledConfiguration *sledConfiguration = [[zt_RfidAppEngine sharedAppEngine] sledConfiguration];
    localSledConfiguration.currentDpoEnable = [NSNumber numberWithBool:enabled];
    sledConfiguration.currentDpoEnable = [NSNumber numberWithBool:enabled];
    activeProfile = [NSString stringWithFormat:@"%ld",(long)[sender tag]];
    [[NSUserDefaults standardUserDefaults] setValue:activeProfile forKey:DEFAULTS_KEY];
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:ANTENNA_DEFAULTS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setupConfigurationInitial];
}

/// Link profile button action to open the links pickerview.
- (void)linkBtnAction:(UIButton*)sender
{
    pickerType = PROFILE_LINK_PICKER;
    pickerView.tag = sender.tag;
    [pickerBgView setHidden:NO];
    [self.view bringSubviewToFront:pickerBgView];
    [pickerView reloadAllComponents];
    [pickerView selectRow:selectedLinkIndex inComponent:INDEX animated:NO];

}

/// Link profile button action to open the sessions pickerview.
- (void)sessionBtnAction:(UIButton*)sender
{
    pickerType = PROFILE_SESSION_PICKER;
    pickerView.tag = sender.tag;
    [pickerBgView setHidden:NO];
    [self.view bringSubviewToFront:pickerBgView];
    [pickerView reloadAllComponents];
    [pickerView selectRow:selectedSessionIndex inComponent:INDEX animated:NO];
}

/// Button action to close the picker.
/// @param sender We can pass the any uicomponent as a sender.
- (IBAction)closePicker:(id)sender
{
    [pickerBgView setHidden:YES];
    [self.view sendSubviewToBack:pickerBgView];
}

/// Gets the number of components for the picker view.
/// @param pickerView A picker view displays one or more wheels that the user manipulates to select items.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

/// Returns the number of rows for a component.
/// @param pickerView A picker view displays one or more wheels that the user manipulates to select items.
/// @param component Gets the number of components for the picker view.
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if ([pickerType  isEqual: PROFILE_LINK_PICKER]) {
        return [_linkChoices count];
    }else
    {
        return [_sessionChoices count];
    }
}

/// Called by the picker view when it needs the title to use for a given row in a given component.
/// @param pickerView A picker view displays one or more wheels that the user manipulates to select items.
/// @param row Provides the current index of the picker cell.
/// @param component Gets the number of components for the picker view.
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if ([pickerType  isEqual: PROFILE_LINK_PICKER]) {
        return [_linkChoices objectAtIndex:row];
    }else
    {
        return [_sessionChoices objectAtIndex:row];
    }
    
}

/// Called by the picker view when the user selects a row in a component.
/// @param pickerView  A picker view displays one or more wheels that the user manipulates to select items.
/// @param row Provides the current index of the picker cell.
/// @param component Gets the number of components for the picker view.
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    zt_SledConfiguration *localSled = [[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy];
    if ([pickerType  isEqual: PROFILE_LINK_PICKER]) {
        selectedLinkIndex = row;
        [self setLinkProfileIndex:[_linkChoices objectAtIndex:row]];
    }else
    {
        localSled.currentSession = [localSled.mapperSession getEnumByIndx:(int)row];
        selectedSessionIndex = row;
    }
    activeProfile = [NSString stringWithFormat:@"%ld",(long)[pickerView tag]];
    
    [[NSUserDefaults standardUserDefaults] setValue:activeProfile forKey:DEFAULTS_KEY];
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:ANTENNA_DEFAULTS_KEY];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:PROFILE_DEFAULTS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self setupConfigurationInitial];
}

/// To set the proper link profile index to fetch the correct link profile name.
/// @param value The profile name from the selected link profile.
- (void)setLinkProfileIndex:(NSString *)value
{
    zt_SledConfiguration *localSled = [[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy];
    srfidLinkProfile* linkProfileObject = [self getMatchingLinkProfileObject:value linkProfileArray:localSled.linkProfilesArray];
    int profileIndex = [self getMatchingIndexLegacyIndex:value linkProfileArray:localSled.linkProfilesArray];
    localSled.currentAntennaLinkProfile = profileIndex;
    localSled.currentAntennaTari = linkProfileObject.getMaxTari;
    localSled.currentAntennaPie = linkProfileObject.getPIE;
}

/// Fetch the proper matching index from the link profile array.
/// @param profileName The profile name from the link profile object.
/// @param linkProfilesArray The link profiles array to fetch matching index.
-(srfidLinkProfile*)getMatchingLinkProfileObject:(NSString*)profileName linkProfileArray:(NSMutableArray*) linkProfilesArray{
    
    srfidLinkProfile* object = [[srfidLinkProfile alloc]init];
    for (zt_LinkProfileObject *linkProfileObject in linkProfilesArray) {
        if ([linkProfileObject.profileName isEqual:profileName]){
            object =  linkProfileObject.modeTableEntry;
            break;
        }
    }
    return object;
}

/// Fetch the proper matching index from legacy linkprofile array.
/// @param profileName The profile name from the linkprofile object.
/// @param linkProfilesArray The linkprofiles array to fetch matching index.
-(int)getMatchingIndexLegacyIndex:(NSString*)profileName linkProfileArray:(NSMutableArray*) linkProfilesArray{
    
    int legacyProfileIndex = 0;
    
    for (zt_LinkProfileObject *linkProfileObject in linkProfilesArray) {
        
        NSLog(@" Profile %@",linkProfileObject.legacyProfileName);
        if ([linkProfileObject.profileName isEqual:profileName]){
            legacyProfileIndex = [linkProfileObject.modeTableEntry getRFModeIndex];
            break;
        }
    }
    return legacyProfileIndex;
}


#pragma mark - Dark mode handling

/// Check whether darkmode is changed
/// @param traitCollection The traits, such as the size class and scale factor.
-(void)darkModeCheck:(UITraitCollection *)traitCollection
{
    self.view.backgroundColor = [UIColor getDarkModeViewBackgroundColor:traitCollection];
    profile_table.backgroundColor =  [UIColor getDarkModeViewBackgroundColor:traitCollection];
}

/// Notifies the container that its trait collection changed.
/// @param traitCollection The traits, such as the size class and scale factor,.
/// @param coordinator The transition coordinator object managing the size change.
- (void)willTransitionToTraitCollection:(UITraitCollection *)traitCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    NSLog(@"Dark Mode change");
    [self darkModeCheck:traitCollection];
    [profile_table reloadData];
}

@end

