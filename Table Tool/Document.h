//
//  Document.h
//  Table Tool
//
//  Created by Andreas Aigner on 06.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Document : NSDocument <NSTableViewDataSource, NSTableViewDelegate>

@property NSMutableArray *data;
@property long maxColumnNumber;

@property (unsafe_unretained) IBOutlet NSTableView *tableView;

-(void)updateTableColumns;
-(void)setNewColumn:(long)columnIndex;

-(IBAction)addLineAbove:(id)sender;
-(IBAction)addLineBelow:(id)sender;
-(IBAction)addColumnLeft:(id)sender;
-(IBAction)addColumnRight:(id)sender;

@end

