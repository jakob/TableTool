//
//  Document.h
//  Table Tool
//
//  Created by Andreas Aigner on 06.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSVMutableConfiguration.h"

@interface Document : NSDocument <NSTableViewDataSource, NSTableViewDelegate>

@property NSMutableArray *data;
@property long maxColumnNumber;
@property CSVMutableConfiguration *config;

@property IBOutlet NSTableView *tableView;

-(void)updateTableColumns;

-(IBAction)addLineAbove:(id)sender;
-(IBAction)addLineBelow:(id)sender;
-(IBAction)addColumnLeft:(id)sender;
-(IBAction)addColumnRight:(id)sender;
-(IBAction)deleteRow:(id)sender;
-(IBAction)deleteColumn:(id)sender;
-(IBAction)updateConfiguration:(id)sender;

@end

