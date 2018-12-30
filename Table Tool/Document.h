//
//  Document.h
//  Table Tool
//
//  Created by Andreas Aigner on 06.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSVConfiguration.h"
#import "CSVReader.h"
#import "TTFormatViewController.h"

@interface Document : NSDocument <NSTableViewDataSource, NSTableViewDelegate, TTFormatViewControllerDelegate>

@property NSMutableArray *data;
@property long maxColumnNumber;
@property CSVReader *csvReader;
@property CSVConfiguration *csvConfig;

@property IBOutlet NSTableView *tableView;
@property IBOutlet NSSplitView *splitView;
@property (strong) IBOutlet NSButton *toolBarButtonDeleteColumn;
@property (strong) IBOutlet NSSegmentedControl *toolBarButtonsAddColumn;
@property (strong) IBOutlet NSSegmentedControl *toolBarButtonsAddRow;
@property (strong) IBOutlet NSToolbarItem *toolbarItemAddColumn;
@property (strong) IBOutlet NSToolbarItem *toolbarItemAddRow;
@property (strong) IBOutlet NSButton *toolBarButtonDeleteRow;
@property (strong) IBOutlet NSToolbarItem *toolbarItemDeleteColumn;
@property (strong) IBOutlet NSToolbarItem *toolbarItemDeleteRow;

-(IBAction)addColumn:(id)sender;
-(IBAction)addRow:(id)sender;
-(void)addRowAbove:(id)sender;
-(void)addRowBelow:(id)sender;
-(void)addColumnLeft:(id)sender;
-(void)addColumnRight:(id)sender;
-(IBAction)deleteRow:(id)sender;
-(IBAction)deleteColumn:(id)sender;
-(IBAction)exportFile:(id)sender;

-(void)configurationChangedForFormatViewController:(TTFormatViewController *)formatViewController;

@end

