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
-(void)revertEditing;
-(void)useInputConfig:(TTFormatViewController *)formatViewController;
-(void)useFirstRowAsHeader:(TTFormatViewController *)formatViewController;
@end

@interface TTFormatViewController : NSViewController


@property (readonly) BOOL checkBoxIsChecked;
@property CSVConfiguration *config;
@property IBOutlet NSSegmentedControl *quoteControl;
@property IBOutlet NSSegmentedControl *escapeControl;
@property IBOutlet NSSegmentedControl *separatorControl;
@property IBOutlet NSSegmentedControl *decimalControl;
@property IBOutlet NSPopUpButton *encodingMenu;
@property IBOutlet NSTextField *helpText;
@property IBOutlet NSButton *revertButton;
@property IBOutlet NSTextField *viewTitle;
@property IBOutlet NSButton *checkBox;
@property id<TTFormatViewControllerDelegate> delegate;
@property (strong) IBOutlet NSLayoutConstraint *bottomConstraint;

- (IBAction)updateConfiguration:(id)sender;
- (IBAction)clickCheckBox:(id)sender;
- (IBAction)revertEditing:(id)sender;
- (void)showRevertMessage;
- (void)setCheckButton;
- (void)setControlTitle:(NSString *)title;
- (void)selectFormatByConfig;

@end
