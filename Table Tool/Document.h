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

@property IBOutlet NSTableView *tableView;
@property IBOutlet NSSplitView *splitView;
@property (strong) IBOutlet NSButton *toolBarButtonDeleteColumn;
@property (strong) IBOutlet NSSegmentedControl *toolBarButtonsAddColumn;
@property (strong) IBOutlet NSSegmentedControl *toolBarButtonsAddRow;
@property (strong) IBOutlet NSToolbarItem *toolbarItemAddColumn;
@property (strong) IBOutlet NSToolbarItem *toolbarItemAddRow;
@property (strong) IBOutlet NSButtonCell *toolBarButtonDeleteRow;


-(IBAction)addColumn:(id)sender;
-(IBAction)addRow:(id)sender;
-(void)addRowAbove:(id)sender;
-(void)addRowBelow:(id)sender;
-(void)addColumnLeft:(id)sender;
-(void)addColumnRight:(id)sender;
-(IBAction)deleteRow:(id)sender;
-(IBAction)deleteColumn:(id)sender;
-(IBAction)toggleFormatView:(id)sender;

-(void)configurationChangedForFormatViewController:(TTFormatViewController *)formatViewController;
-(void)useInputConfig:(TTFormatViewController *)formatViewController;
-(void)revertEditing;
-(void)useFirstRowAsHeader:(TTFormatViewController *)formatViewController;

@end

