//
//  Document.m
//  Table Tool
//
//  Created by Andreas Aigner on 06.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import "Document.h"

@interface Document () {
    NSCell *dataCell;
}

@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
        _data = [[NSMutableArray alloc]init];
        _maxColumnNumber = 1;
    }
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    [self updateTableColumns];
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    
    NSMutableString *dataString = [[NSMutableString alloc]init];
    
    for(int i = 0; i < [_data count]; ++i) {
        NSMutableArray *rowArray = _data[i];
        for(NSTableColumn *col in _tableView.tableColumns.copy) {
            NSInteger columnIndex = col.identifier.integerValue;
            
            if(columnIndex >= [rowArray count]) {
                [dataString appendString:@""];
            } else {
                [dataString appendString:rowArray[columnIndex]];
            }
            [dataString appendString:@","];
        }
        [dataString deleteCharactersInRange:NSMakeRange([dataString length] -1,1)];
        [dataString appendString:@"\n"];
    }
    [dataString deleteCharactersInRange:NSMakeRange([dataString length] -1,1)];
    
    NSData *finalData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    
    return finalData;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    
    NSString *csvData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *tempData = [csvData componentsSeparatedByString:@"\n"];
    _maxColumnNumber = 1;
    [_data removeAllObjects];
    
    for(int i = 0; i < [tempData count]; ++i) {
        NSArray *rowData = [((NSString *)tempData[i]) componentsSeparatedByString:@","];
        [_data addObject:rowData.mutableCopy];
        
        if(_maxColumnNumber < [rowData count]) {
            _maxColumnNumber = [rowData count];
        }
    }
    
    [self updateTableColumns];
    [self.tableView reloadData];
    return YES;
}

#pragma mark - tableViewDataSource, delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_data count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    
    if(_data.count >= rowIndex+1) {
        NSArray *rowArray = _data[rowIndex];
        if(rowArray.count >= tableColumn.identifier.integerValue+1){
            return rowArray[tableColumn.identifier.integerValue];
        }
    }
    return nil;
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    
    NSMutableArray *rowArray = _data[rowIndex];
    if([rowArray count] < tableColumn.identifier.integerValue) {
        for(NSUInteger i = [rowArray count]; i <= tableColumn.identifier.integerValue; ++i){
            [rowArray addObject:@""];
        }
    }
    rowArray[tableColumn.identifier.integerValue] = (NSString *)object;
    _data[rowIndex] = rowArray;
}

#pragma mark - organizeTableView

-(void)updateTableColumns {
    for(NSTableColumn *col in self.tableView.tableColumns.mutableCopy) {
        [self.tableView removeTableColumn:col];
    }
    for(int i = 0; i < _maxColumnNumber; ++i) {
        [self.tableView addTableColumn: [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"%d",i]]];
    }
}

-(void)setNewColumn:(long) columnIndex {
    
    if(![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
    long columnIdentifier = _maxColumnNumber;
    NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"%ld",columnIdentifier]];
    col.dataCell = dataCell;
    [self.tableView addTableColumn:col];
    [self.tableView moveColumn:[self.tableView numberOfColumns]-1 toColumn:columnIndex];
    
    for(NSMutableArray *rowArray in _data) {
        [rowArray addObject:@""];
    }
    
    _maxColumnNumber++;
    
    [self.tableView selectColumnIndexes:[NSIndexSet indexSetWithIndex:columnIndex] byExtendingSelection:NO];
    [self.tableView scrollColumnToVisible:columnIndex];
}

-(IBAction)addLineAbove:(id)sender {
    
    if(![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
    if([self.tableView numberOfColumns] == 0){
        [self setNewColumn:0];
    }
    
    NSIndexSet *rowIndexes = [self.tableView selectedRowIndexes];
    long rowIndex = [rowIndexes firstIndex] > [rowIndexes lastIndex] ? [rowIndexes lastIndex] : [rowIndexes firstIndex];
    
    
    if([self.tableView selectedRow] == -1){
        rowIndex = 0;
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [self.tableView beginUpdates];
            [_data insertObject:[[NSMutableArray alloc] init] atIndex:rowIndex];
            [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:rowIndex] withAnimation:NSTableViewAnimationSlideDown];
            [self.tableView endUpdates];
        } completionHandler:^{
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
            [self.tableView scrollRowToVisible:rowIndex];
        }];
    }else{
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [self.tableView beginUpdates];
            [_data insertObject:[[NSMutableArray alloc] init] atIndex:rowIndex];
            [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:rowIndex] withAnimation:NSTableViewAnimationSlideDown];
            [self.tableView endUpdates];
        } completionHandler:^{
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
            [self.tableView scrollRowToVisible:rowIndex];
        }];
    }
}

-(IBAction)addLineBelow:(id)sender {
    
    if(![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
    if([self.tableView numberOfColumns] == 0){
        [self setNewColumn:0];
    }
    
    NSIndexSet *rowIndexes = [self.tableView selectedRowIndexes];
    long rowIndex = [rowIndexes firstIndex] > [rowIndexes lastIndex] ? [rowIndexes firstIndex]+1 : [rowIndexes lastIndex]+1;
    
    if([self.tableView selectedRow] == -1){
        rowIndex = [self.tableView numberOfRows];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [self.tableView beginUpdates];
            [_data insertObject:[[NSMutableArray alloc] init] atIndex:rowIndex];
            [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:rowIndex] withAnimation:NSTableViewAnimationSlideDown];
            [self.tableView endUpdates];
        } completionHandler:^{
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
            [self.tableView scrollRowToVisible:rowIndex];
        }];
    }else{
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [self.tableView beginUpdates];
            [_data insertObject:[[NSMutableArray alloc] init] atIndex:rowIndex];
            [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:rowIndex] withAnimation:NSTableViewAnimationSlideDown];
            [self.tableView endUpdates];
        } completionHandler:^{
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
            [self.tableView scrollRowToVisible:rowIndex];
        }];
    }
}

-(IBAction)addColumnLeft:(id)sender {
    
    long columnIndex;
    
    if([self.tableView selectedColumn] == -1){
        if([self.tableView editedColumn] == -1){
            columnIndex = 0;
        } else {
            columnIndex = [self.tableView editedColumn];
        }
    } else {
        NSIndexSet *columnIndexes = [self.tableView selectedColumnIndexes];
        columnIndex = [columnIndexes firstIndex] > [columnIndexes lastIndex] ? [columnIndexes lastIndex] : [columnIndexes firstIndex];
    }
    [self setNewColumn:columnIndex];
}

-(IBAction)addColumnRight:(id)sender {
   
    long columnIndex;

    if([self.tableView selectedColumn] == -1){
        if([self.tableView editedColumn] == -1){
            columnIndex = [self.tableView numberOfColumns];
        } else {
            columnIndex = [self.tableView editedColumn]+1;
        }
    } else {
        NSIndexSet *columnIndexes = [self.tableView selectedColumnIndexes];
        columnIndex = [columnIndexes firstIndex] > [columnIndexes lastIndex] ? [columnIndexes firstIndex]+1 : [columnIndexes lastIndex]+1;
    }
    [self setNewColumn:columnIndex];
}

-(IBAction)deleteColumn:(id)sender {
    long selectedIndex = [self.tableView selectedColumn];
    if(selectedIndex == -1 || ![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
    NSTableColumn *col = self.tableView.tableColumns[selectedIndex];
    [self.tableView removeTableColumn:col];
    
    if(selectedIndex == [self.tableView numberOfColumns]){
        [self.tableView selectColumnIndexes:[NSIndexSet indexSetWithIndex: [self.tableView numberOfColumns]-1] byExtendingSelection:NO];
    }else{
        [self.tableView selectColumnIndexes:[NSIndexSet indexSetWithIndex: selectedIndex] byExtendingSelection:NO];
    }
}

-(IBAction)deleteRow:(id)sender {
    long selectedIndex = [self.tableView selectedRow];
    if(selectedIndex == -1 || ![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
    [_data removeObjectAtIndex:selectedIndex];
    [self.tableView beginUpdates];
    [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:selectedIndex ] withAnimation:NSTableViewAnimationSlideUp];
    [self.tableView endUpdates];
    
    if(selectedIndex == [self.tableView numberOfRows]){
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex: [self.tableView numberOfRows]-1] byExtendingSelection:NO];
    } else {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedIndex] byExtendingSelection:NO];
    }
}


@end
