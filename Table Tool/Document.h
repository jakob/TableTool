//
//  Document.h
//  Table Tool
//
//  Created by Andreas Aigner on 06.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSVConfiguration.h"
#import "TTFormatViewController.h"

@interface Document : NSDocument <NSTableViewDataSource, NSTableViewDelegate>

@property NSMutableArray *data;
@property long maxColumnNumber;
@property CSVConfiguration *inputConfig;
@property CSVConfiguration *outputConfig;
@property NSString *errorMessage;

@property IBOutlet NSTableView *tableView;
@property IBOutlet NSBox *errorBox;
@property IBOutlet NSTextField *errorLabel;
@property IBOutlet NSSplitView *splitView;

-(IBAction)addLineAbove:(id)sender;
-(IBAction)addLineBelow:(id)sender;
-(IBAction)addColumnLeft:(id)sender;
-(IBAction)addColumnRight:(id)sender;
-(IBAction)deleteRow:(id)sender;
-(IBAction)deleteColumn:(id)sender;
-(IBAction)toggleFormatView:(id)sender;

-(void)configurationChangedForFormatViewController:(TTFormatViewController *)formatViewController;
-(void)useInputConfig:(TTFormatViewController *)formatViewController;
-(void)revertEditing;
-(void)useFirstRowAsHeader:(TTFormatViewController *)formatViewController;

@end

