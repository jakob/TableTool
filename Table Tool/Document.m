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
#import "CSVConfiguration.h"

@interface Document () {
    NSCell *dataCell;
    NSData *savedData;
    BOOL edited;
    BOOL didNotMoveColumn;
    BOOL newFile;
}

@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
        _data = [[NSMutableArray alloc]init];
        _maxColumnNumber = 1;
        _config = [[CSVConfiguration alloc]init];
        newFile = YES;
    }
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    dataCell = [self.tableView.tableColumns.firstObject dataCell];
    [self updateTableColumns];
    if(_errorMessage){
        self.errorLabel.stringValue = _errorMessage;
        self.errorBox.hidden = NO;
    }
}

+ (BOOL)autosavesInPlace {
    return YES;
}


- (NSString *)windowNibName {
    return @"Document";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    
    NSMutableArray *columnsOrder = [[NSMutableArray alloc] init];
    for(NSTableColumn *col in self.tableView.tableColumns) {
        [columnsOrder addObject:col.identifier];
    }
    
    CSVWriter *writer = [[CSVWriter alloc] initWithDataArray:_data columnsOrder:columnsOrder configuration:_config];
    NSData *finalData = [writer writeDataWithError:outError];
    if(finalData == nil){
        return NO;
    }
    
    newFile = NO;
    [self dataGotEdited];
    return finalData;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    
    [self.undoManager removeAllActions];
    newFile = NO;
    savedData = data;
    
    _maxColumnNumber = 1;
    [_data removeAllObjects];
    
    CSVReader *reader = [[CSVReader alloc ]initWithData:data configuration: _config];
    while(![reader isAtEnd]) {
        NSError *error = nil;
        NSArray *oneReadLine = [reader readLineWithError:&error];
        if(oneReadLine == nil) {
            _errorMessage = [NSString stringWithFormat:@"%@\n%@",error.localizedDescription,error.localizedRecoverySuggestion];
            self.errorLabel.stringValue = _errorMessage;
            self.errorBox.hidden = NO;
            break;
        }
        [_data addObject:oneReadLine];
        if(_maxColumnNumber < [[_data lastObject] count]){
            _maxColumnNumber = [[_data lastObject] count];
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
    
    [[self.undoManager prepareWithInvocationTarget:self] restoreObjectValue:rowArray[tableColumn.identifier.integerValue] forTableColumn:tableColumn row:rowIndex reload:YES];
    
    if(![(NSString *)object isEqualToString:rowArray[tableColumn.identifier.integerValue]]){
        [self dataGotEdited];
    }
    rowArray[tableColumn.identifier.integerValue] = (NSString *)object;
    _data[rowIndex] = rowArray;
    if (shouldReload) [self.tableView reloadData];
}

-(void)tableViewColumnDidMove:(NSNotification *)aNotification {
    
    [self dataGotEdited];
    
    if(!didNotMoveColumn){
        [self.undoManager setActionName:@"Move Column"];
        
        NSNumber *oldIndex = [aNotification.userInfo valueForKey:@"NSOldColumn"];
        NSNumber *newIndex = [aNotification.userInfo valueForKey:@"NSNewColumn"];
        [[self.undoManager prepareWithInvocationTarget:self] moveColumnFrom:newIndex.longValue toIndex:oldIndex.longValue];
    }
    
    [self updateTableColumnsNames];
}

#pragma mark - updateTableView

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

#pragma mark - buttonActions

-(IBAction)addLineAbove:(id)sender {
    
    if(![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
    [self dataGotEdited];
    long rowIndex;
    NSIndexSet *rowIndexes = [self.tableView selectedRowIndexes];
    if(rowIndexes.count != 0){
        rowIndex = [rowIndexes firstIndex] > [rowIndexes lastIndex] ? [rowIndexes lastIndex] : [rowIndexes firstIndex];
    }else{
        rowIndex = 0;
    }
    
    [self addRowAtIndex:rowIndex];
    [self.undoManager setActionName:@"Add Line Above"];
}

-(IBAction)addLineBelow:(id)sender {
    
    if(![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
    [self dataGotEdited];
    long rowIndex;
    NSIndexSet *rowIndexes = [self.tableView selectedRowIndexes];
    if(rowIndexes.count != 0){
        rowIndex = [rowIndexes firstIndex] > [rowIndexes lastIndex] ? [rowIndexes firstIndex]+1 : [rowIndexes lastIndex]+1;
    }else{
        rowIndex = [self.tableView numberOfRows];
    }
    
    [self addRowAtIndex:rowIndex];
    [self.undoManager setActionName:@"Add Line below"];
}

-(IBAction)addColumnLeft:(id)sender {
    
    if(![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
    [self dataGotEdited];
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
    [self addColumnAtIndex:columnIndex];
    [self.undoManager setActionName:@"Add Column left"];
}

-(IBAction)addColumnRight:(id)sender {
    
    if(![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
    [self dataGotEdited];
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
    [self addColumnAtIndex:columnIndex];
    [self.undoManager setActionName:@"Add Column right"];
}

-(IBAction)deleteColumn:(id)sender {
    
    long selectedIndex = [self.tableView selectedColumn];
    if(selectedIndex == -1 || ![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
    [self dataGotEdited];
    
    NSIndexSet *columnIndexes = [self.tableView selectedColumnIndexes];
    [self deleteColumnsAtIndexes:columnIndexes];
    [self.undoManager setActionName:@"Delete Column(s)"];
}

-(IBAction)deleteRow:(id)sender {
    
    long selectedIndex = [self.tableView selectedRow];
    if(selectedIndex == -1 || ![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
    [self dataGotEdited];
    
    NSIndexSet *rowIndexes = [self.tableView selectedRowIndexes];
    [self deleteRowsAtIndexes:rowIndexes];
    [self.undoManager setActionName:@"Delete Row(s)"];
}

#pragma mark - buttonActionImplementations

-(void)deleteRowsAtIndexes:(NSIndexSet *)rowIndexes{
    
    NSMutableArray *toDeleteRows = [[NSMutableArray alloc]initWithArray:[_data objectsAtIndexes:rowIndexes]];
    [[self.undoManager prepareWithInvocationTarget:self] restoreRowsWithContent:toDeleteRows atIndexes:rowIndexes];
    
    [_data removeObjectsAtIndexes:rowIndexes];
    [self.tableView beginUpdates];
    [self.tableView removeRowsAtIndexes:rowIndexes withAnimation:NSTableViewAnimationSlideUp];
    [self.tableView endUpdates];
    long selectedIndex = [rowIndexes firstIndex] > [rowIndexes lastIndex] ? [rowIndexes lastIndex] : [rowIndexes firstIndex];
    
    if(selectedIndex == [self.tableView numberOfRows]){
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex: [self.tableView numberOfRows]-1] byExtendingSelection:NO];
    } else {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedIndex] byExtendingSelection:NO];
    }
}

-(void)restoreRowsWithContent:(NSMutableArray *)rowContents atIndexes:(NSIndexSet *)rowIndexes {
    
    [[self.undoManager prepareWithInvocationTarget:self] deleteRowsAtIndexes:rowIndexes];
    
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexes:rowIndexes withAnimation:0];
    [_data insertObjects:rowContents atIndexes:rowIndexes];
    [self.tableView endUpdates];
    
    [self.tableView selectRowIndexes:rowIndexes byExtendingSelection:NO];
}

-(void)addRowAtIndex:(long)rowIndex {
    
    if([self.tableView numberOfColumns] == 0){
        [self addColumnAtIndex:0];
    }
    
    NSMutableArray *toInsertArray = [[NSMutableArray alloc]init];
    for (int i = 0; i < _maxColumnNumber; ++i) {
        [toInsertArray addObject:@""];
    }
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [self.tableView beginUpdates];
        [_data insertObject:toInsertArray atIndex:rowIndex];
        [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:rowIndex] withAnimation:NSTableViewAnimationSlideDown];
        [self.tableView endUpdates];
    } completionHandler:^{
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
        [self.tableView scrollRowToVisible:rowIndex];
        
    }];
    
    NSIndexSet *toRedoIndexSet = [NSIndexSet indexSetWithIndex:rowIndex];
    [[self.undoManager prepareWithInvocationTarget:self] deleteRowsAtIndexes:toRedoIndexSet];
}

-(void)addColumnAtIndex:(long) columnIndex {
    
    didNotMoveColumn = YES;
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
    [self.tableView scrollColumnToVisible:columnIndex];
    didNotMoveColumn = NO;
    
    [[self.undoManager prepareWithInvocationTarget:self] deleteColumnsAtIndexes:[NSIndexSet indexSetWithIndex:columnIndex]];
}

-(void)deleteColumnsAtIndexes:(NSIndexSet *) columnIndexes{
    
    didNotMoveColumn = YES;
    NSMutableArray *columnIds = [[NSMutableArray alloc]init];
    NSArray *tableColumns = self.tableView.tableColumns.copy;
    [columnIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSTableColumn *col = tableColumns[idx];
        [columnIds addObject:col.identifier];
        [self.tableView removeTableColumn:col];
    }];
    didNotMoveColumn = NO;
    
    [self updateTableColumnsNames];
    
    long selectedIndex = [columnIndexes firstIndex] > [columnIndexes lastIndex] ? [columnIndexes lastIndex] : [columnIndexes firstIndex];
    
    if(selectedIndex == [self.tableView numberOfColumns]){
        [self.tableView selectColumnIndexes:[NSIndexSet indexSetWithIndex: [self.tableView numberOfColumns]-1] byExtendingSelection:NO];
    }else{
        [self.tableView selectColumnIndexes:[NSIndexSet indexSetWithIndex: selectedIndex] byExtendingSelection:NO];
    }
    
    [[self.undoManager prepareWithInvocationTarget:self] restoreColumns:columnIds atIndexes:columnIndexes];
    
}

-(void)restoreColumns:(NSMutableArray *)columnIds atIndexes:(NSIndexSet *)columnIndexes{
    
    didNotMoveColumn = YES;
    NSMutableIndexSet *columnIndexesCopy = columnIndexes.mutableCopy;
    for(int i = 0; i < columnIds.count; i++){
        NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:columnIds[i]];
        col.dataCell = dataCell;
        [self.tableView addTableColumn:col];
        NSUInteger index = [columnIndexesCopy firstIndex];
        [columnIndexesCopy removeIndex:0];
        [self.tableView moveColumn:[self.tableView numberOfColumns]-1 toColumn:index];
    }
    didNotMoveColumn = NO;
    
    [self updateTableColumnsNames];
    
    [self.tableView selectColumnIndexes:columnIndexes byExtendingSelection:NO];
    [[self.undoManager prepareWithInvocationTarget:self]deleteColumnsAtIndexes:columnIndexes];
    
}

-(void)moveColumnFrom:(long)oldIndex toIndex:(long)newIndex {
    [self.tableView moveColumn:oldIndex toColumn:newIndex];
    [self updateTableColumnsNames];
}

#pragma mark - configuration

-(IBAction)updateConfiguration:(id)sender {
    
    _config.encoding = [self.encodingMenu selectedTag];
    if([self.separatorControl selectedSegment] == 2) {
        _config.columnSeparator = @"\t";
    }else{
        _config.columnSeparator = [self.separatorControl labelForSegment:[self.separatorControl selectedSegment] ];
    }
    _config.decimalMark = [self.decimalControl labelForSegment:[self.decimalControl selectedSegment]];
    _config.quoteCharacter = [self.quoteControl labelForSegment:[self.quoteControl selectedSegment]];
    [self.escapeControl setLabel:_config.quoteCharacter forSegment:1];
    _config.escapeCharacter = [self.escapeControl labelForSegment:[self.escapeControl selectedSegment]];
    
    if(!newFile) {
        NSError *outError;
        BOOL didReload = [self reloadDataWithError:&outError];
        if (!didReload) {
            self.errorLabel.stringValue = [NSString stringWithFormat:@"%@\n%@",outError.localizedDescription,outError.localizedRecoverySuggestion];
            self.errorBox.hidden = NO;
        } else {
            self.errorBox.hidden = YES;
        }
    }
    
}

-(BOOL)reloadDataWithError:(NSError**)error {
    _maxColumnNumber = 1;
    [_data removeAllObjects];
    
    NSError *outError;
    CSVReader *reader = [[CSVReader alloc ]initWithData:savedData configuration: _config];
    while(![reader isAtEnd]) {
        NSArray *oneReadLine = [reader readLineWithError:&outError];
        if(oneReadLine == nil) {
            if (error) *error = outError;
            [self updateTableColumns];
            [self.tableView reloadData];
            return NO;
        }
        [_data addObject:oneReadLine];
        if(_maxColumnNumber < [[_data lastObject] count]){
            _maxColumnNumber = [[_data lastObject] count];
        }
    }
    
    [self updateTableColumns];
    [self.tableView reloadData];
    return YES;
}

-(void)dataGotEdited {
    if(!newFile){
        edited = YES;
        self.encodingMenu.enabled = NO;
        self.separatorControl.enabled = NO;
        self.decimalControl.enabled = NO;
        self.quoteControl.enabled = NO;
        self.escapeControl.enabled = NO;
    }
}

@end
