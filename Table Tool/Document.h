//
//  Document.h
//  Table Tool
//
//  Created by Andreas Aigner on 06.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSVConfiguration.h"

@interface Document : NSDocument <NSTableViewDataSource, NSTableViewDelegate>

@property NSMutableArray *data;
@property long maxColumnNumber;
@property CSVConfiguration *config;

@property IBOutlet NSTableView *tableView;
@property IBOutlet NSSegmentedControl *quoteControl;
@property IBOutlet NSSegmentedControl *escapeControl;
@property IBOutlet NSSegmentedControl *separatorControl;
@property IBOutlet NSSegmentedControl *decimalControl;
@property IBOutlet NSPopUpButton *encodingMenu;
@property IBOutlet NSBox *errorBox;
@property IBOutlet NSTextField *errorLabel;

-(IBAction)addLineAbove:(id)sender;
-(IBAction)addLineBelow:(id)sender;
-(IBAction)addColumnLeft:(id)sender;
-(IBAction)addColumnRight:(id)sender;
-(IBAction)deleteRow:(id)sender;
-(IBAction)deleteColumn:(id)sender;
-(IBAction)updateConfiguration:(id)sender;

@end

