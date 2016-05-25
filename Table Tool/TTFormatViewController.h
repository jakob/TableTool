//
//  TTFormatViewController.h
//  Table Tool
//
//  Created by Andreas Aigner on 24.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSVConfiguration.h"

@class TTFormatViewController;

@protocol TTFormatViewControllerDelegate
-(void)configurationChangedForFormatViewController:(TTFormatViewController *)formatViewController;
-(void)useFirstRowAsHeader:(TTFormatViewController *)formatViewController;
-(void)confirmFormat:(TTFormatViewController *)formatViewController;
@end

@interface TTFormatViewController : NSViewController

@property (readonly) BOOL isInputController;
@property (readonly) BOOL firstRowAsHeader;
@property CSVConfiguration *config;
@property id<TTFormatViewControllerDelegate> delegate;
@property IBOutlet NSSegmentedControl *escapeControl;
@property IBOutlet NSSegmentedControl *separatorControl;
@property IBOutlet NSSegmentedControl *decimalControl;
@property IBOutlet NSPopUpButton *encodingMenu;
@property IBOutlet NSButton *useFirstRowAsHeaderCheckbox;
@property IBOutlet NSButton *quoteCheckbox;

- (IBAction)updateConfiguration:(id)sender;
- (IBAction)useFirstRowAsHeaderClicked:(id)sender;

- (instancetype)initAsInputController:(BOOL)inputController;
- (void)selectFormatByConfig;
- (void)uncheckCheckbox;
- (void)useLocale;
- (void)setEnabled:(BOOL)enabled;

@end
