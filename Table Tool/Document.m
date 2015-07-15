//
//  Document.m
//  Table Tool
//
//  Created by Andreas Aigner on 06.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import "Document.h"
#import "CSVReader.h"
#import "CSVWriter.h"

@interface Document () {
    NSCell *dataCell;
    NSMutableArray *columnsOrder;
}

@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
        _data = [[NSMutableArray alloc]init];
        _maxColumnNumber = 1;
        columnsOrder = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    dataCell = [self.tableView.tableColumns.firstObject dataCell];
    [self updateTableColumns];
    [self updateTableColumnsOrder];
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
    
    CSVWriter *writer = [[CSVWriter alloc] initWithDataArray:_data andColumnsOrder:columnsOrder];
    NSData *finalData = [writer writeDataWithError:outError];
    if(finalData == nil){
        return NO;
    }
    
    return finalData;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    
    _maxColumnNumber = 1;
    [_data removeAllObjects];
    
    CSVReader *reader = [[CSVReader alloc ]initWithData:data];
    while(![reader isAtEnd]) {
        NSArray *oneReadLine = [reader readLineWithError:outError];
        if(oneReadLine == nil) {
            return NO;
        }
        [_data addObject:oneReadLine];
        if(_maxColumnNumber < [[_data lastObject] count]){
            _maxColumnNumber = [[_data lastObject] count];
        }
    }
    
    [self updateTableColumns];
    [self updateTableColumnsOrder];
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
    
    [self restoreObjectValue:object forTableColumn:tableColumn row:rowIndex reload:NO];
    [self.undoManager setActionName:@"Edit Cell"];
    
}

-(void)restoreObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex reload:(BOOL)shouldReload {
    
    NSMutableArray *rowArray = _data[rowIndex];
    if([rowArray count] < tableColumn.identifier.integerValue) {
        for(NSUInteger i = rowArray.count; i <= tableColumn.identifier.integerValue+1; ++i){
            [rowArray addObject:@""];
        }
    }
    
    //For debugging only:
    //NSLog(@"rowIndex:%d, rowArray length:%d, tablecolumn identifier:%d",rowIndex,rowArray.count,tableColumn.identifier.integerValue);
    
    [[self.undoManager prepareWithInvocationTarget:self] restoreObjectValue:rowArray[tableColumn.identifier.integerValue] forTableColumn:tableColumn row:rowIndex reload:YES];
    rowArray[tableColumn.identifier.integerValue] = (NSString *)object;
    _data[rowIndex] = rowArray;
    if (shouldReload) [self.tableView reloadData];
}

-(void)tableViewColumnDidMove:(NSNotification *)aNotification {
    [self updateTableColumnsNames];
    [self updateTableColumnsOrder];
}

#pragma mark - organizeTableView

-(void)updateTableColumns {
    if (!self.tableView) return;
    
    for(NSTableColumn *col in self.tableView.tableColumns.mutableCopy) {
        [self.tableView removeTableColumn:col];
    }
    for(int i = 0; i < _maxColumnNumber; ++i) {
        NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"%d",i]];
        tableColumn.dataCell = dataCell;
        tableColumn.title = [NSString stringWithFormat:@"Column %d", i+1];
        [self.tableView addTableColumn: tableColumn];
    }
}

-(void)updateTableColumnsNames {
    for(int i = 0; i < [self.tableView.tableColumns count]; i++) {
        NSTableColumn *tableColumn = self.tableView.tableColumns[i];
        tableColumn.title = [NSString stringWithFormat:@"Column %d", i+1];
    }
}

-(void)updateTableColumnsOrder {
    [columnsOrder removeAllObjects];
    for(NSTableColumn *col in self.tableView.tableColumns) {
        [columnsOrder addObject:col.identifier];
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
    [self updateTableColumnsNames];
    [self updateTableColumnsOrder];
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
    NSMutableArray *toInsertArray = [[NSMutableArray alloc]init];
    for (int i = 0; i < _maxColumnNumber; ++i) {
        [toInsertArray addObject:@""];
    }
    
    if([self.tableView selectedRow] == -1){
        rowIndex = 0;
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [self.tableView beginUpdates];
            [_data insertObject:toInsertArray atIndex:rowIndex];
            [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:rowIndex] withAnimation:NSTableViewAnimationSlideDown];
            [self.tableView endUpdates];
        } completionHandler:^{
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
            [self.tableView scrollRowToVisible:rowIndex];
        }];
    }else{
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [self.tableView beginUpdates];
            [_data insertObject:toInsertArray atIndex:rowIndex];
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
    NSMutableArray *toInsertArray = [[NSMutableArray alloc]init];
    for (int i = 0; i < _maxColumnNumber; ++i) {
        [toInsertArray addObject:@""];
    }
    
    if([self.tableView selectedRow] == -1){
        rowIndex = [self.tableView numberOfRows];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [self.tableView beginUpdates];
            [_data insertObject:toInsertArray atIndex:rowIndex];
            [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:rowIndex] withAnimation:NSTableViewAnimationSlideDown];
            [self.tableView endUpdates];
        } completionHandler:^{
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
            [self.tableView scrollRowToVisible:rowIndex];
        }];
    }else{
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [self.tableView beginUpdates];
            [_data insertObject:toInsertArray atIndex:rowIndex];
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
    
    NSIndexSet *columnIndexes = [self.tableView selectedColumnIndexes];
    NSArray *tableColumns = self.tableView.tableColumns.copy;
    [columnIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSTableColumn *col = tableColumns[idx];
        [self.tableView removeTableColumn:col];
    }];
    [self updateTableColumnsNames];
    [self updateTableColumnsOrder];
    
    selectedIndex = [columnIndexes firstIndex] > [columnIndexes lastIndex] ? [columnIndexes lastIndex] : [columnIndexes firstIndex];
    
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
    
    NSIndexSet *rowIndexes = [self.tableView selectedRowIndexes];
    
    [_data removeObjectsAtIndexes:rowIndexes];
    [self.tableView beginUpdates];
    [self.tableView removeRowsAtIndexes:rowIndexes withAnimation:NSTableViewAnimationSlideUp];
    [self.tableView endUpdates];
    selectedIndex = [rowIndexes firstIndex] > [rowIndexes lastIndex] ? [rowIndexes lastIndex] : [rowIndexes firstIndex];
    
    if(selectedIndex == [self.tableView numberOfRows]){
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex: [self.tableView numberOfRows]-1] byExtendingSelection:NO];
    } else {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedIndex] byExtendingSelection:NO];
    }
}

@end
