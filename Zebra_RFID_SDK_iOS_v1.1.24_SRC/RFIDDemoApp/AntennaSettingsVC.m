/******************************************************************************
 *
 *       Copyright Zebra Technologies, Inc. 2014 - 2015
 *
 *       The copyright notice above does not evidence any
 *       actual or intended publication of such source code.
 *       The code contains Zebra Technologies
 *       Confidential Proprietary Information.
 *
 *
 *  Description:  AntennaSettingsVC.m
 *
 *  Notes:
 *
 ******************************************************************************/

#import "AntennaSettingsVC.h"
#import "RfidAppEngine.h"
#import "ui_config.h"
#import "LinkProfileObject.h"

#define ZT_VC_ANTENNA_CELL_IDX_POWER_LEVEL            0
#define ZT_VC_ANTENNA_CELL_IDX_LINK_PROFILE           1
#define ZT_VC_ANTENNA_CELL_IDX_PIE                    2
#define ZT_VC_ANTENNA_CELL_IDX_TARI                   3
#define ZT_VC_ANTENNA_CELL_IDX_DO_SELECT              4

#define ZT_VC_ANTENNA_OPTION_ID_NOT_AN_OPTION         -1
#define ZT_VC_ANTENNA_OPTION_ID_POWER_LEVEL           0
#define ZT_VC_ANTENNA_OPTION_ID_LINK_PROFILE          1
#define ZT_VC_ANTENNA_OPTION_ID_PIE                   2
#define ZT_VC_ANTENNA_OPTION_ID_TARI                  3
#define ZT_VC_ANTENNA_OPTION_ID_DO_SELECT             4

@interface zt_AntennaSettingsVC ()
    @property zt_SledConfiguration *localSled;
@end

/* TBD: save & apply (?) configuration during hide */
@implementation zt_AntennaSettingsVC

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil)
    {
        m_PickerCellIdx = -1;
        m_PresentedOptionId = ZT_VC_ANTENNA_OPTION_ID_NOT_AN_OPTION;
        [self createPreconfiguredOptionCells];
    }
    return self;
}

- (void)dealloc
{
    if (nil != m_cellLinkProfile)
    {
        [m_cellLinkProfile release];
    }
    if (nil != m_cellPowerLevel)
    {
        [m_cellPowerLevel release];
    }
    if (nil != cellTari)
    {
        [cellTari release];
    }
    if (nil != cellPie)
    {
        [cellPie release];
    }
    if (nil != m_cellDoSelect)
    {
        [m_cellDoSelect release];
    }
    if (nil != m_GestureRecognizer)
    {
        [m_GestureRecognizer release];
    }
    if (nil != m_cellPicker)
    {
        [m_cellPicker release];
    }
    [m_tblOptions release];
    [super dealloc];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [_localSled setAntennaOptionsWithConfig:[[[zt_RfidAppEngine sharedAppEngine] sledConfiguration] getAntennaConfig]];
    
    [m_tblOptions setDelegate:self];
    [m_tblOptions setDataSource:self];
    [m_tblOptions registerClass:[zt_InfoCellView class] forCellReuseIdentifier:ZT_CELL_ID_INFO];
    [m_tblOptions registerClass:[zt_PickerCellView class] forCellReuseIdentifier:ZT_CELL_ID_PICKER];
    
    /* prevent table view from showing empty not-required cells or extra separators */
    [m_tblOptions setTableFooterView:[[[UIView alloc] initWithFrame:CGRectZero] autorelease]];
        
    /* set title */
    [self setTitle:@"Antenna"];
    
    /* configure layout via constraints */
    [self.view removeConstraints:[self.view constraints]];
    
    NSLayoutConstraint *c1 = [NSLayoutConstraint constraintWithItem:m_tblOptions attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self.view addConstraint:c1];
    
    NSLayoutConstraint *c2 = [NSLayoutConstraint constraintWithItem:m_tblOptions attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];
    [self.view addConstraint:c2];
    
    NSLayoutConstraint *c3 = [NSLayoutConstraint constraintWithItem:m_tblOptions attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];
    [self.view addConstraint:c3];
    
    NSLayoutConstraint *c4 = [NSLayoutConstraint constraintWithItem:m_tblOptions attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    [self.view addConstraint:c4];
    
    /* just to hide keyboard */
    m_GestureRecognizer = [[UITapGestureRecognizer alloc]
                           initWithTarget:self action:@selector(dismissKeyboard)];
    [m_GestureRecognizer setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:m_GestureRecognizer];

    [self setupConfigurationInitial];
}

- (void) viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePowerLevelChanged:) name:UITextFieldTextDidChangeNotification object:[m_cellPowerLevel getTextField]];
    /* just for auto scroll on keyboard events */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    inventoryRequested = [[[zt_RfidAppEngine sharedAppEngine] operationEngine] getStateInventoryRequested];
    
    if (inventoryRequested == NO) {
        self.view.userInteractionEnabled = YES;
        m_tblOptions.userInteractionEnabled = YES;
    }else
    {
        self.view.userInteractionEnabled = NO;
        m_tblOptions.userInteractionEnabled = NO;
    }
    
}

- (int)recalcCellIndex:(int)cell_index
{
    if (-1 == m_PickerCellIdx)
    {
        return cell_index;
    }
    else
    {
        if (cell_index < m_PickerCellIdx)
        {
            return cell_index;
        }
        else
        {
            return (cell_index + 1);
        }
    }
}

/// Notifies the view controller that its view was added to a view hierarchy
/// @param animated If true, the view was added to the window using an animation.
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self darkModeCheck:self.view.traitCollection];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:[m_cellPowerLevel getTextField]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    zt_SledConfiguration *configuration = [[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy];
    if([[m_cellPowerLevel getCellData] length]>0)
    {
        NSString * floatString = [m_cellPowerLevel getCellData];
        configuration.currentAntennaPowerLevel = [floatString floatValue];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createPreconfiguredOptionCells
{
    m_cellPowerLevel = [[zt_LabelInputFieldCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ZT_CELL_ID_INFO];
    [m_cellPowerLevel setKeyboardType:UIKeyboardTypeDecimalPad];
    m_cellLinkProfile = [[zt_InfoCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ZT_CELL_ID_INFO];
    cellTari = [[zt_InfoCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ZT_CELL_ID_INFO];
    cellPie = [[zt_InfoCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ZT_CELL_ID_INFO];
    m_cellPicker = [[zt_PickerCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ZT_CELL_ID_PICKER];
    m_cellDoSelect = [[zt_InfoCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ZT_CELL_ID_INFO];
    
    [m_cellPowerLevel setSelectionStyle:UITableViewCellSelectionStyleNone];
    [m_cellPowerLevel setDataFieldWidth:40];
    [m_cellPowerLevel setInfoNotice:ZT_STR_SETTINGS_ANTENNA_POWER_LEVEL];
    
    [m_cellLinkProfile setStyle:ZT_CELL_INFO_STYLE_GRAY_DISCLOSURE_INDICATOR];
    [m_cellLinkProfile setInfoNotice:ZT_STR_SETTINGS_ANTENNA_LINK_PROFILE];
    
    [cellTari setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cellTari setInfoNotice:ZT_STR_SETTINGS_ANTENNA_TARI];
    
    [cellPie setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cellPie setInfoNotice:ANTENNA_KEY_PIE];
    
    [m_cellPicker setSelectionStyle:UITableViewCellSelectionStyleNone];
    [m_cellPicker setDelegate:self];
    
    [m_cellDoSelect setStyle:ZT_CELL_INFO_STYLE_GRAY_DISCLOSURE_INDICATOR];
    [m_cellDoSelect setInfoNotice:ZT_STR_SETTINGS_ANTENNA_DO_SELECT];
}

- (void)setupConfigurationInitial
{
    /* TBD: configure based on app / reader settings */
    zt_SledConfiguration *configuration = [[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy];
    
    NSNumber *powerLevelKey = [NSNumber numberWithInt:configuration.currentAntennaPowerLevel];
    [m_cellPowerLevel setData:[NSString stringWithFormat:@"%1.0f",[powerLevelKey floatValue]]];
    
    NSNumber *linkProfileKey = [NSNumber numberWithInt:configuration.currentAntennaLinkProfile];
    int linkProfileIndex = [linkProfileKey intValue];
    [m_cellLinkProfile setData:(NSString*)[self getMatchingProfileNameByIndex:linkProfileIndex linkProfileArray:configuration.linkProfilesArray]];
    
    NSNumber *tari = [NSNumber numberWithInt:configuration.currentAntennaTari];
    if (configuration.currentAntennaTari != 0) {
        [cellTari setData:(NSString *)tari];
    }else
    {
        tariArray = TARI_ARRAY_12500_25000
        [cellTari setData:(NSString *)[tariArray lastObject]];
    }
    
    NSNumber *pie = [NSNumber numberWithInt:configuration.currentAntennaPie];
    if (configuration.currentAntennaPie != 0) {
        [cellPie setData:(NSString *)pie];
    }else
    {
        pieArray = PIE_ARRAY_GENERAL
        [cellPie setData:(NSString *)[pieArray firstObject]];
    }
    
    NSNumber *doSelectKey = [NSNumber numberWithInt:configuration.currentAntennaDoSelect];
    [m_cellDoSelect setData:(NSString*)[configuration.antennaOptionsDoSelect objectForKey:doSelectKey]];
    
    /* hide picker cells */
    m_PickerCellIdx = -1;
    [m_tblOptions reloadData];
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

/// Fetch the index according to the selected tari and pie value from the linkprofiles array.
/// @param profileName The profile name from the linkprofile object.
/// @param tariValue The selected tari value from the list.
/// @param pieValue The selected pie value from the list.
/// @param linkProfilesArray The linkprofiles array to fetch matching index.
- (int)getMatchingIndexAccordingTariAndPie:(NSString*)profileName tariValue:(int)tariValue pieValue: (int)pieValue linkProfileArray:(NSMutableArray*) linkProfilesArray
{
    int modeIndex = 0;
    for (zt_LinkProfileObject *linkProfileObject in linkProfilesArray) {
        
        if ([linkProfileObject.profileName isEqual:profileName] && ([linkProfileObject.modeTableEntry getPIE] == pieValue) && ([linkProfileObject.modeTableEntry getMinTari] <= tariValue) && (tariValue <= [linkProfileObject.modeTableEntry getMaxTari])){
            modeIndex = [linkProfileObject.modeTableEntry getRFModeIndex];
            return modeIndex;
        }
    }
    return -1;
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

/// Fetch the matching link profile object by using link profile index.
/// @param profileIndex The profile index from the link profile object.
/// @param linkProfilesArray The link profiles array to fetch matching index.
-(srfidLinkProfile*)getMatchingLinkProfileObjectByLinkProfileIndex:(int)profileIndex linkProfileArray:(NSMutableArray*) linkProfilesArray{
    
    srfidLinkProfile* object = [[srfidLinkProfile alloc]init];
    for (zt_LinkProfileObject *linkProfileObject in linkProfilesArray) {
        if ([linkProfileObject.modeTableEntry getRFModeIndex] == profileIndex){
            object =  linkProfileObject.modeTableEntry;
            break;
        }
    }
    return object;
}

/* ###################################################################### */
/* ########## ISelectionTableVCDelegate Protocol implementation ######### */
/* ###################################################################### */
- (void)didChangeSelectedOption:(NSString *)value
{
    zt_SledConfiguration *localSled = [[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy];
    srfidLinkProfile* linkProfileObject = [self getMatchingLinkProfileObject:value linkProfileArray:localSled.linkProfilesArray];
    if (ZT_VC_ANTENNA_OPTION_ID_LINK_PROFILE == m_PresentedOptionId)
    {
        int profileIndex = [self getMatchingIndexLegacyIndex:value linkProfileArray:localSled.linkProfilesArray];
        localSled.currentAntennaLinkProfile = profileIndex;
        
        NSNumber *linkProfileKey = [NSNumber numberWithInt:localSled.currentAntennaLinkProfile];
        [m_cellLinkProfile setData:(NSString*)[localSled.antennaOptionsLinkProfile objectForKey:linkProfileKey]];
        
        [cellTari setData:[NSString stringWithFormat:@"%d",linkProfileObject.getMaxTari]];
        localSled.currentAntennaTari = linkProfileObject.getMaxTari;
        
        [cellPie setData:[NSString stringWithFormat:@"%d",linkProfileObject.getPIE]];
        localSled.currentAntennaPie = linkProfileObject.getPIE;
        
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:ANTENNA_DEFAULTS_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    else if (ZT_VC_ANTENNA_OPTION_ID_DO_SELECT == m_PresentedOptionId)
    {
        localSled.currentAntennaDoSelect = [[zt_SledConfiguration getKeyFromDictionary:localSled.antennaOptionsDoSelect withValue:value] boolValue];
        NSNumber *doSelectKey = [NSNumber numberWithInt:localSled.currentAntennaTari];
        [m_cellDoSelect setData:(NSString*)[localSled.antennaOptionsDoSelect objectForKey:doSelectKey]];
    }
}

/* ###################################################################### */
/* ########## Table View Data Source Delegate Protocol implementation ### */
/* ###################################################################### */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // change to 5 for tari and do select options
    return 4 + ((m_PickerCellIdx != -1) ? 1 : 0);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.0;
    
    UITableViewCell *_info_cell = nil;
    
    int cell_idx = (int)[indexPath row];
    
    if (-1 != m_PickerCellIdx && cell_idx == m_PickerCellIdx)
    {
        _info_cell = m_cellPicker;
    }
    else if ([self recalcCellIndex:ZT_VC_ANTENNA_CELL_IDX_LINK_PROFILE] == cell_idx)
    {
        _info_cell = m_cellLinkProfile;
    }
    else if ([self recalcCellIndex:ZT_VC_ANTENNA_CELL_IDX_POWER_LEVEL] == cell_idx)
    {
        _info_cell = m_cellPowerLevel;
    }
    else if ([self recalcCellIndex:ZT_VC_ANTENNA_CELL_IDX_PIE] == cell_idx)
    {
        _info_cell = cellPie;
    }
    else if ([self recalcCellIndex:ZT_VC_ANTENNA_CELL_IDX_TARI] == cell_idx)
    {
        _info_cell = cellTari;
    }
    else if ([self recalcCellIndex:ZT_VC_ANTENNA_CELL_IDX_DO_SELECT] == cell_idx)
    {
        _info_cell = m_cellDoSelect;
    }
    
    if (nil != _info_cell)
    {
        [_info_cell setNeedsUpdateConstraints];
        [_info_cell updateConstraintsIfNeeded];
        
        [_info_cell setNeedsLayout];
        [_info_cell layoutIfNeeded];
        
        height = [_info_cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        height += 1.0; /* for cell separator */
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int cell_idx = (int)[indexPath row];
    
    if (-1 != m_PickerCellIdx && cell_idx == m_PickerCellIdx)
    {
        return m_cellPicker;
    }
    else if ([self recalcCellIndex:ZT_VC_ANTENNA_CELL_IDX_LINK_PROFILE] == cell_idx)
    {
        [m_cellLinkProfile darkModeCheck:self.view.traitCollection];
        return m_cellLinkProfile;
    }
    else if ([self recalcCellIndex:ZT_VC_ANTENNA_CELL_IDX_POWER_LEVEL] == cell_idx)
    {
        [m_cellPowerLevel darkModeCheck:self.view.traitCollection];
        return m_cellPowerLevel;
    }
    else if ([self recalcCellIndex:ZT_VC_ANTENNA_CELL_IDX_PIE] == cell_idx)
    {
        [cellPie darkModeCheck:self.view.traitCollection];
        return cellPie;
    }
    else if ([self recalcCellIndex:ZT_VC_ANTENNA_CELL_IDX_TARI] == cell_idx)
    {
        [cellTari darkModeCheck:self.view.traitCollection];
        return cellTari;
    }
    else if ([self recalcCellIndex:ZT_VC_ANTENNA_CELL_IDX_DO_SELECT] == cell_idx)
    {
        [m_cellDoSelect darkModeCheck:self.view.traitCollection];
        return m_cellDoSelect;
    }
    return nil;
}

/* ###################################################################### */
/* ########## Table View Delegate Protocol implementation ############### */
/* ###################################################################### */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int cell_idx = (int)[indexPath row];
    int row_to_hide = -1;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    int main_cell_idx = -1;
    
    /* enable view animation that was disabled during
    switching between segments - see configureForSelectedOperation */
    [UIView setAnimationsEnabled:YES];
    
    /* expected index for new picker cell */
    row_to_hide = m_PickerCellIdx;
    
    zt_SelectionTableVC *vc = (zt_SelectionTableVC*)[[UIStoryboard storyboardWithName:@"RFIDDemoApp" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ID_SELECTION_TABLE_VC"];
    [vc setDelegate:self];

    
    zt_SledConfiguration *configuration = [[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy];
    
    if ([self recalcCellIndex:ZT_VC_ANTENNA_CELL_IDX_PIE] == cell_idx)
    {
        
        NSNumber *linkProfileKey = [NSNumber numberWithInt:configuration.currentAntennaLinkProfile];
        zt_SledConfiguration *localSled = [[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy];
        int linkProfileIndex = [linkProfileKey intValue];
        srfidLinkProfile* linkProfileObject = [self getMatchingLinkProfileObjectByLinkProfileIndex:linkProfileIndex linkProfileArray:localSled.linkProfilesArray];
    
        if (linkProfileObject.getPIE == LINK_PROFILE_TARI_668)
        {
            pieArray = PIE_ARRAY_668
        }else
        {
            pieArray = PIE_ARRAY_GENERAL
        }
        [m_cellPicker setChoices:pieArray];
        for (int pieIndex = 0; pieIndex < [pieArray count]; pieIndex++)
        {
            NSNumber *pieValue = [NSNumber numberWithInt:configuration.currentAntennaPie];
            int selectedVal = [[pieArray objectAtIndex:pieIndex] intValue];
            NSNumber *currentPie = [NSNumber numberWithInt:selectedVal];
            
            if (currentPie == pieValue) {
                m_SelectedOptionPie = pieIndex;
            }
        }
        [m_cellPicker setSelectedChoice:m_SelectedOptionPie];
        main_cell_idx = ZT_VC_ANTENNA_CELL_IDX_PIE;
    }
    else if ([self recalcCellIndex:ZT_VC_ANTENNA_CELL_IDX_LINK_PROFILE] == cell_idx)
    {
        m_PresentedOptionId = ZT_VC_ANTENNA_OPTION_ID_LINK_PROFILE;
        [vc setCaption:ZT_STR_SETTINGS_ANTENNA_LINK_PROFILE];
        [vc setOptionsWithStringArray:[configuration getLinkProfileArray]];
        NSNumber *linkProfileKey = [NSNumber numberWithInt:configuration.currentAntennaLinkProfile];
        int linkProfileIndex = [linkProfileKey intValue];
        NSString * profileName = [self getMatchingProfileNameByIndex:linkProfileIndex linkProfileArray:configuration.linkProfilesArray];
        [vc setSelectedValue:(NSString*)profileName];
    }
    else if ([self recalcCellIndex:ZT_VC_ANTENNA_CELL_IDX_DO_SELECT] == cell_idx)
    {
        m_PresentedOptionId = ZT_VC_ANTENNA_OPTION_ID_DO_SELECT;
        [vc setCaption:ZT_STR_SETTINGS_ANTENNA_DO_SELECT];
        [vc setOptionsWithDictionary:configuration.antennaOptionsDoSelect withStringPrefix:nil];
        NSNumber *key = [NSNumber numberWithInt:configuration.currentAntennaDoSelect];
        [vc setSelectedValue:(NSString*)[configuration.antennaOptionsDoSelect objectForKey:key]];
    }else if ([self recalcCellIndex:ZT_VC_ANTENNA_CELL_IDX_TARI] == cell_idx)
    {
        NSNumber *linkProfileKey = [NSNumber numberWithInt:configuration.currentAntennaLinkProfile];
        int linkProfileIndex = [linkProfileKey intValue];
        zt_SledConfiguration *localSledConfiguration = [[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy];
        srfidLinkProfile* linkProfileObject = [self getMatchingLinkProfileObjectByLinkProfileIndex:linkProfileIndex linkProfileArray:localSledConfiguration.linkProfilesArray];
        
        tariArray = [self updateTariArray:linkProfileObject configuration:configuration];
        
        [m_cellPicker setChoices:tariArray];
        for (int tariIndex = 0; tariIndex < [tariArray count]; tariIndex++)
        {
            NSNumber *tariValue = [NSNumber numberWithInt:configuration.currentAntennaTari];
            int selectedValue = [[tariArray objectAtIndex:tariIndex] intValue];
            NSNumber *currentTari = [NSNumber numberWithInt:selectedValue];
            
            if (currentTari == tariValue) {
                m_SelectedOptionTari = tariIndex;
            }
        }
        [m_cellPicker setSelectedChoice:m_SelectedOptionTari];
        main_cell_idx = ZT_VC_ANTENNA_CELL_IDX_TARI;
    }
    else
    {
        if([[m_cellPowerLevel getCellData] length]>0)
            {
                NSString * floatString = [m_cellPowerLevel getCellData];
                configuration.currentAntennaPowerLevel = [floatString floatValue];
            }

    }
    if (ZT_VC_ANTENNA_CELL_IDX_LINK_PROFILE == cell_idx){
        [[self navigationController] pushViewController:vc animated:YES];
    }
    
    if (-1 != main_cell_idx)
    {
        int _picker_cell_idx = m_PickerCellIdx;

        if (-1 != row_to_hide)
        {
            m_PickerCellIdx = -1; // required for adequate assessment of number of rows during delete operation
            [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row_to_hide inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }

        /* if picker was not shown for this cell -> let's show it */
        if ((main_cell_idx + 1) != _picker_cell_idx)
        {
            m_PickerCellIdx = main_cell_idx + 1;
        }

        if (m_PickerCellIdx != -1)
        {
            [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:m_PickerCellIdx inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:m_PickerCellIdx inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
    }
}


/// Updating the tari array depends on the selected link profile.
/// @param linkProfileObject The link profile object from the selected link profile data.
/// @param configuration The sled configuration to reduce more declarations.
- (NSArray*)updateTariArray:(srfidLinkProfile*)linkProfileObject configuration:(zt_SledConfiguration*)sledConfiguration
{
    if ((linkProfileObject.getMinTari == MIN_TARI_25000 && sledConfiguration.isMinTari_12500) || (linkProfileObject.getMaxTari == MIN_TARI_23000 && linkProfileObject.getMinTari == MIN_TARI_12500)) {
        if (sledConfiguration.isStepTari_6300) {
            tariArray = TARI_ARRAY_25000_6300
        }else
        {
            tariArray = TARI_ARRAY_12500_25000
        }
    }else if ((linkProfileObject.getMinTari == MIN_TARI_25000 && sledConfiguration.isStepTari_non_0) || (linkProfileObject.getMaxTari == MIN_TARI_23000 && linkProfileObject.getMinTari == MIN_TARI_18800))
    {
        tariArray = TARI_ARRAY_18800_25000
    }else if (linkProfileObject.getMaxTari == MIN_TARI_18800 && linkProfileObject.getMinTari == MIN_TARI_12500)
    {
        if (sledConfiguration.isStepTari_6300) {
            tariArray = TARI_ARRAY_18800_6300
        }else
        {
            tariArray = TARI_ARRAY_12500_18800
        }
    }else if (linkProfileObject.getMinTari == MIN_TARI_18800)
    {
        tariArray = TARI_ARRAY_18800
    }else if (linkProfileObject.getMinTari == MIN_TARI_25000 && !sledConfiguration.isStepTari_non_0)
    {
        tariArray = TARI_ARRAY_25000
    }else if (linkProfileObject.getMaxTari == MIN_TARI_6250)
    {
        tariArray = TARI_ARRAY_6250
    }else if (linkProfileObject.getMaxTari == MIN_TARI_668)
    {
        tariArray = TARI_ARRAY_668
    }else
    {
        tariArray = TARI_ARRAY_GENERAL
    }
    return tariArray;
}

/* ###################################################################### */
/* ########## IOptionCellDelegate Protocol implementation ############### */
/* ###################################################################### */
- (void)didChangeValue:(id)option_cell
{
    zt_OptionCellView *_cell = (zt_OptionCellView*)option_cell;
    
    if (YES == [_cell isKindOfClass:[zt_PickerCellView class]])
    {
        int choice = [(zt_PickerCellView*)_cell getSelectedChoice];
        
        zt_SledConfiguration *localSledConfiguration = [[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy];
        
        NSNumber *linkProfileKey = [NSNumber numberWithInt:localSledConfiguration.currentAntennaLinkProfile];
        int linkProfileIndex = [linkProfileKey intValue];
        [m_cellLinkProfile setData:(NSString*)[self getMatchingProfileNameByIndex:linkProfileIndex linkProfileArray:localSledConfiguration.linkProfilesArray]];
        
        NSString * profileString = [self getMatchingProfileNameByIndex:linkProfileIndex linkProfileArray:localSledConfiguration.linkProfilesArray];
        
        tariArray = [self updateTariArray:[self getMatchingLinkProfileObjectByLinkProfileIndex:linkProfileIndex linkProfileArray:localSledConfiguration.linkProfilesArray] configuration:localSledConfiguration];
        int tariValue = localSledConfiguration.currentAntennaTari;
        if (ZT_VC_ANTENNA_CELL_IDX_TARI == (m_PickerCellIdx - 1))
        {
            tariValue = [[tariArray objectAtIndex:choice] intValue];
        }
       
        int pieValue = localSledConfiguration.currentAntennaPie;
        if (ZT_VC_ANTENNA_CELL_IDX_PIE == (m_PickerCellIdx - 1))
        {
            pieValue = [[pieArray objectAtIndex:choice] intValue];
        }
        int profileIndex = [self getMatchingIndexAccordingTariAndPie:profileString tariValue:tariValue pieValue:pieValue linkProfileArray:localSledConfiguration.linkProfilesArray];
        
        localSledConfiguration.currentAntennaLinkProfile = profileIndex;
        localSledConfiguration.currentAntennaPie = pieValue;
        localSledConfiguration.currentAntennaTari = tariValue;
        
        if (ZT_VC_ANTENNA_CELL_IDX_PIE == (m_PickerCellIdx - 1))
        {
            [cellPie setData:(NSString *)[pieArray objectAtIndex:choice]];
        }
        if (ZT_VC_ANTENNA_CELL_IDX_TARI == (m_PickerCellIdx - 1))
        {
            [cellTari setData:(NSString *)[tariArray objectAtIndex:choice]];
        }
    }
}

- (void)handlePowerLevelChanged:(NSNotification *)notif
{
    NSMutableString *string = [[NSMutableString alloc] init];
    NSMutableString *_input = [[NSMutableString alloc] init];
    [_input setString:[[m_cellPowerLevel getCellData] uppercaseString]];
    
    if ([self checkNumInput:_input] == YES)
    {
        [string setString:_input];
        if ([string isEqualToString:[m_cellPowerLevel getCellData]] == NO)
        {
            [m_cellPowerLevel setData:string];
        }
        
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:ANTENNA_DEFAULTS_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else
    {
        /* restore previous one */
        [m_cellPowerLevel setData:string];
        /* clear undo stack as we have restored previous stack (i.e. user's action
         had no effect) */
        [[[m_cellPowerLevel getTextField] undoManager] removeAllActions];
    }
    [_input release];
    
}

- (BOOL)checkNumInput:(NSString *)address
{
    BOOL _valid_address_input = YES;
    unsigned char _ch = 0;
    for (int i = 0; i < [address length]; i++)
    {
        _ch = [address characterAtIndex:i];
        /* :, 0 .. 9, A .. F */
        if ((_ch < 48) || (_ch > 57) )
        {
            _valid_address_input = NO;
            break;
        }
    }
    return _valid_address_input;
}

- (void)keyboardWillShow:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(m_tblOptions.contentInset.top, 0.0, kbSize.height, 0.0);
    m_tblOptions.contentInset = contentInsets;
    m_tblOptions.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(m_tblOptions.contentInset.top, 0.0, 0.0, 0.0);
    m_tblOptions.contentInset = contentInsets;
    m_tblOptions.scrollIndicatorInsets = contentInsets;
}

- (void)dismissKeyboard
{
    [self.view endEditing:YES];
}

#pragma mark - Dark mode handling

/// Check whether darkmode is changed
/// @param traitCollection The traits, such as the size class and scale factor.
-(void)darkModeCheck:(UITraitCollection *)traitCollection
{
    [m_tblOptions reloadData];
}

/// Notifies the container that its trait collection changed.
/// @param traitCollection The traits, such as the size class and scale factor,.
/// @param coordinator The transition coordinator object managing the size change.
- (void)willTransitionToTraitCollection:(UITraitCollection *)traitCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    NSLog(@"Dark Mode change");
    [self darkModeCheck:traitCollection];
}

@end
