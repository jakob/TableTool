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
#import "CSVHeuristic.h"
#import "TTErrorViewController.h"
#import "ToolbarIcons.h"

@interface Document () {
    NSCell *dataCell;
    NSData *savedData;
    NSMutableArray *firstRow;
    NSError *readingError;
    BOOL edited;
    BOOL didNotMoveColumn;
    BOOL newFile;
    TTFormatViewController *inputController;
    TTFormatViewController *outputController;
    TTErrorViewController *errorController;
}

@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
        _data = [[NSMutableArray alloc]init];
        _maxColumnNumber = 1;
        _inputConfig = [[CSVConfiguration alloc]init];
        _outputConfig = _inputConfig.copy;
        newFile = YES;
    }
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    dataCell = [self.tableView.tableColumns.firstObject dataCell];
    [self updateTableColumns];
    
    outputController = [[TTFormatViewController alloc]init];
    [self.splitView addSubview:outputController.view positioned:NSWindowBelow relativeTo:nil];
    if(!newFile){
        [outputController setControlTitle:@"Output File Format"];
        [outputController setCheckButton];
    }else{
        [outputController setControlTitle:@"File Format"];
    }
    outputController.delegate = self;
    
    if(!newFile){
        inputController = [[TTFormatViewController alloc]init];
        [self.splitView addSubview:inputController.view positioned:NSWindowBelow relativeTo:nil];
        [inputController setControlTitle:@"Input File Format"];
        [inputController setCheckButton];
        inputController.delegate = self;
        inputController.config = _inputConfig;
        _outputConfig = _inputConfig.copy;
        outputController.config = _outputConfig;
        [inputController selectFormatByConfig];
        [outputController selectFormatByConfig];
    }
    if(readingError) dispatch_async(dispatch_get_main_queue(), ^{
        [self displayError:readingError];
    });
    
    [self updateToolbarIcons];

}


+ (BOOL)autosavesInPlace {
    return YES;
}

- (NSString *)windowNibName {
    return @"Document";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    
    if(inputController && inputController.checkBoxIsChecked){
        NSMutableArray *dataFirstRow = [[NSMutableArray alloc]init];
        for(int i = 0; i < _maxColumnNumber; i++){
            [dataFirstRow addObject:@""];
        }
        for(NSTableColumn * col in self.tableView.tableColumns){
            [dataFirstRow replaceObjectAtIndex:col.identifier.integerValue withObject:col.title];
        }
        [_data insertObject:dataFirstRow atIndex:0];
    }
    
    NSError *error;
    CSVWriter *writer = [[CSVWriter alloc] initWithDataArray:_data columnsOrder:[self getColumnsOrder] configuration:_outputConfig];
    NSData *finalData = [writer writeDataWithError:&error];
    if(finalData == nil){
        if(error) {
            *outError = error;
            [self displayError:error];
        }
    }
    
    if(inputController && inputController.checkBoxIsChecked){
        [_data removeObjectAtIndex:0];
    }
    return finalData;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    
    [self.undoManager removeAllActions];
    newFile = NO;
    CSVHeuristic *formatHeuristic = [[CSVHeuristic alloc]initWithData:data];
    _inputConfig = [formatHeuristic calculatePossibleFormat];

    savedData = data;
    _maxColumnNumber = 1;
    [_data removeAllObjects];
    
    CSVReader *reader = [[CSVReader alloc ]initWithData:data configuration: _inputConfig];
    while(![reader isAtEnd]) {
        NSError *error = nil;
        NSArray *oneReadLine = [reader readLineWithError:&error];
        if(oneReadLine == nil) {
            if(error){
                *outError = error;
                readingError = error;
                break;
            }
        }
        [_data addObject:oneReadLine];
        if(_maxColumnNumber < [[_data lastObject] count]){
            _maxColumnNumber = [[_data lastObject] count];
        }
    }
    
    [self updateTableColumns];
    [self initFirstRow];
    [self.tableView reloadData];
    return YES;
}

-(void)displayError:(NSError *)error {
    NSPopover *errorPopover = [[NSPopover alloc]init];
    errorPopover.behavior = NSPopoverBehaviorTransient;
    errorPopover.animates = YES;
    errorController = [[TTErrorViewController alloc]initWithMessage:error.localizedDescription information:error.localizedRecoverySuggestion];
    errorPopover.contentViewController = errorController;
    [inputController view];
    [outputController view];
    switch (error.code) {
        case 1:
            [errorPopover showRelativeToRect:[inputController.encodingMenu bounds] ofView:inputController.encodingMenu preferredEdge:NSMinYEdge];
            break;
        case 2:
        case 3:
            [errorPopover showRelativeToRect:[inputController.view bounds] ofView:inputController.view preferredEdge:NSMinYEdge];
            break;
        case 4:
            [errorPopover showRelativeToRect:[outputController.encodingMenu bounds] ofView:outputController.encodingMenu preferredEdge:NSMinYEdge];
            break;
        default:
            break;
    }
}

#pragma mark - tableViewDataSource, delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_data count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    
    if(_data.count >= rowIndex+1) {
        NSArray *rowArray = _data[rowIndex];
        if(rowArray.count >= tableColumn.identifier.integerValue+1){
            if([rowArray[tableColumn.identifier.integerValue] isKindOfClass:[NSDecimalNumber class]]) {
                return [(NSDecimalNumber *)rowArray[tableColumn.identifier.integerValue] descriptionWithLocale:@{NSLocaleDecimalSeparator:_outputConfig.decimalMark}];
            }
            return rowArray[tableColumn.identifier.integerValue];
        }
    }
    return nil;
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    
    [self restoreObjectValue:object forTableColumn:tableColumn row:rowIndex reload:NO];
    [self.undoManager setActionName:@"Edit Cell"];
    
}

-(void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    if(_data.count <= rowIndex) return;
    NSTextFieldCell *textCell = cell;
    NSArray *rowArray = [_data objectAtIndex:rowIndex];
    if(rowArray.count > tableColumn.identifier.integerValue){
        if([rowArray[tableColumn.identifier.integerValue] isKindOfClass:[NSDecimalNumber class]]){
            textCell.alignment = NSRightTextAlignment;
        }else{
            textCell.alignment = NSLeftTextAlignment;
        }
    }
}

-(void)restoreObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex reload:(BOOL)shouldReload {
    
    NSMutableArray *rowArray = _data[rowIndex];
    if([rowArray count] <= tableColumn.identifier.integerValue) {
        for(NSUInteger i = rowArray.count; i <= tableColumn.identifier.integerValue+1; ++i){
            [rowArray addObject:@""];
        }
    }
    
    [[self.undoManager prepareWithInvocationTarget:self] restoreObjectValue:rowArray[tableColumn.identifier.integerValue] forTableColumn:tableColumn row:rowIndex reload:YES];
    
    if(![object isEqualTo:rowArray[tableColumn.identifier.integerValue]]){
        [self dataGotEdited];
    }
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"^\\s*[+-]?(\\d+\\%@?\\d*|\\d*\\%@?\\d+)([eE][+-]?\\d+)?\\s*$",_outputConfig.decimalMark,_outputConfig.decimalMark] options:0 error:NULL];
    NSString *userInputValue = (NSString *)object;
    if([regex numberOfMatchesInString:userInputValue options:0 range:NSMakeRange(0, [userInputValue length])] == 1){
        rowArray[tableColumn.identifier.integerValue] = [NSDecimalNumber decimalNumberWithString:userInputValue locale:@{NSLocaleDecimalSeparator:_outputConfig.decimalMark}];
    }else{
        rowArray[tableColumn.identifier.integerValue] = userInputValue;
    }
    
    _data[rowIndex] = rowArray;
    if (shouldReload) [self.tableView reloadData];
}

-(void)tableViewColumnDidMove:(NSNotification *)aNotification {
    
    if(!didNotMoveColumn){
        [self.undoManager setActionName:@"Move Column"];
        NSNumber *oldIndex = [aNotification.userInfo valueForKey:@"NSOldColumn"];
        NSNumber *newIndex = [aNotification.userInfo valueForKey:@"NSNewColumn"];
        [self dataGotEdited];
        [[self.undoManager prepareWithInvocationTarget:self] moveColumnFrom:newIndex.longValue toIndex:oldIndex.longValue];
    }
    [self updateTableColumnsNames];
}

-(NSArray *)getColumnsOrder{
    NSMutableArray *columnsOrder = [[NSMutableArray alloc] init];
    for(NSTableColumn *col in self.tableView.tableColumns) {
        [columnsOrder addObject:col.identifier];
    }
    return columnsOrder.copy;
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
        tableColumn.title = [self generateColumnName:i];
        ((NSCell *)tableColumn.headerCell).alignment = NSCenterTextAlignment;
        [self.tableView addTableColumn: tableColumn];
    }
}

-(void)updateTableColumnsNames {
    if(!inputController || !inputController.checkBoxIsChecked){
        for(int i = 0; i < [self.tableView.tableColumns count]; i++) {
            NSTableColumn *tableColumn = self.tableView.tableColumns[i];
            tableColumn.title = [self generateColumnName:i];
            ((NSCell *)tableColumn.headerCell).alignment = NSCenterTextAlignment;
        }
    }
}

-(NSString *)generateColumnName:(int)index {
    int columnBase = 26;
    int digitMax = 7; // ceil(log26(Int32.Max))
    NSString *digits = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    
    if (index < columnBase) {
        return [digits substringWithRange:NSMakeRange(index, 1)];
    }
    
    NSMutableArray *columnName = [[NSMutableArray alloc]initWithCapacity:digitMax];
    for(int i = 0; i < digitMax; i++) {
        columnName[i] = @"";
    }
    
    index++;
    int offset = digitMax;
    while (index > 0) {
        [columnName replaceObjectAtIndex:--offset withObject:[digits substringWithRange:NSMakeRange(--index % columnBase, 1)]];
        index /= columnBase;
    }
    
    return [columnName componentsJoinedByString:@""];
}

-(void)initFirstRow{
    firstRow = [[NSMutableArray alloc]init];
    for(int i = 0; i < _maxColumnNumber; i++){
        firstRow[i] = @"";
    }
    NSArray *dataFirstRow = [_data firstObject];
    for(int i = 0; i < dataFirstRow.count; i++){
        [firstRow replaceObjectAtIndex:i withObject:dataFirstRow[i]];
    }
}

#pragma mark - buttonActions


- (IBAction)addRow:(id)sender {
    switch ([self.toolBarButtonsAddRow selectedSegment]) {
        case 0:
            [self addRowAbove:sender];
            break;
        case 1:
            [self addRowBelow:sender];
        default:
            break;
    }
}

- (IBAction)addColumn:(id)sender {
    switch ([self.toolBarButtonsAddColumn selectedSegment]) {
        case 0:
            [self addColumnLeft:sender];
            break;
        case 1:
            [self addColumnRight:sender];
        default:
            break;
    }
}

-(void)addRowAbove:(id)sender {
    
    if(![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
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

-(void)addRowBelow:(id)sender {
    
    if(![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
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

-(void)addColumnLeft:(id)sender {
    
    if(![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
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

-(void)addColumnRight:(id)sender {
    
    if(![self.tableView.window makeFirstResponder:self.tableView]) {
        NSBeep();
        return;
    }
    
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
    
    NSIndexSet *rowIndexes = [self.tableView selectedRowIndexes];
    [self deleteRowsAtIndexes:rowIndexes];
    [self.undoManager setActionName:@"Delete Row(s)"];
}

#pragma mark - buttonActionImplementations

-(void)deleteRowsAtIndexes:(NSIndexSet *)rowIndexes{
    
    NSMutableArray *toDeleteRows = [[NSMutableArray alloc]initWithArray:[_data objectsAtIndexes:rowIndexes]];
    [[self.undoManager prepareWithInvocationTarget:self] restoreRowsWithContent:toDeleteRows atIndexes:rowIndexes];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [self.tableView beginUpdates];
        [_data removeObjectsAtIndexes:rowIndexes];
        [self.tableView removeRowsAtIndexes:rowIndexes withAnimation:NSTableViewAnimationSlideUp];
        [self.tableView endUpdates];
    } completionHandler:^{
        long selectedIndex = [rowIndexes firstIndex] > [rowIndexes lastIndex] ? [rowIndexes lastIndex] : [rowIndexes firstIndex];
        if(selectedIndex == [self.tableView numberOfRows]){
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex: [self.tableView numberOfRows]-1] byExtendingSelection:NO];
        } else {
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedIndex] byExtendingSelection:NO];
        }
        [self dataGotEdited];
    }];
}

-(void)restoreRowsWithContent:(NSMutableArray *)rowContents atIndexes:(NSIndexSet *)rowIndexes {
    
    [[self.undoManager prepareWithInvocationTarget:self] deleteRowsAtIndexes:rowIndexes];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [self.tableView scrollRowToVisible:[rowIndexes firstIndex]];
        [self.tableView beginUpdates];
        [_data insertObjects:rowContents atIndexes:rowIndexes];
        [self.tableView insertRowsAtIndexes:rowIndexes withAnimation:NSTableViewAnimationSlideDown];
        [self.tableView endUpdates];
    } completionHandler:^{
        [self.tableView selectRowIndexes:rowIndexes byExtendingSelection:NO];
    }];
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
        [self dataGotEdited];
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
    col.title = @"";
    [self.tableView moveColumn:[self.tableView numberOfColumns]-1 toColumn:columnIndex];
    
    for(NSMutableArray *rowArray in _data) {
        [rowArray addObject:@""];
    }
    
    _maxColumnNumber++;
    
    [self.tableView selectColumnIndexes:[NSIndexSet indexSetWithIndex:columnIndex] byExtendingSelection:NO];
    [self updateTableColumnsNames];
    [self.tableView scrollColumnToVisible:columnIndex];
    didNotMoveColumn = NO;
    
    [self dataGotEdited];
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
    
    [self dataGotEdited];
    [[self.undoManager prepareWithInvocationTarget:self] restoreColumns:columnIds atIndexes:columnIndexes];
    
}

-(void)restoreColumns:(NSMutableArray *)columnIds atIndexes:(NSIndexSet *)columnIndexes{
    
    didNotMoveColumn = YES;
    for(int i = 0; i < columnIds.count; i++){
        NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:columnIds[i]];
        col.dataCell = dataCell;
        if(inputController && inputController.checkBoxIsChecked){
            col.title = [firstRow objectAtIndex:((NSString *)columnIds[i]).integerValue];
        }
        ((NSCell *)col.headerCell).alignment = NSCenterTextAlignment;
        [self.tableView addTableColumn:col];
        [self.tableView moveColumn:[self.tableView numberOfColumns]-1 toColumn:[columnIndexes firstIndex]+i];
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

- (IBAction)toggleFormatView:(id)sender {
    if(inputController){
        if(inputController.view.hidden){
            inputController.view.hidden = NO;
        }else{
            inputController.view.hidden = YES;
        }
    }
    
    if(outputController.view.hidden){
        outputController.view.hidden = NO;
    } else {
        outputController.view.hidden = YES;
    }
}

-(void)configurationChangedForFormatViewController:(TTFormatViewController*)formatViewController {
    if([formatViewController.viewTitle.stringValue isEqualToString:@"Input File Format"]) {
        _inputConfig = formatViewController.config;
        NSError *outError;
        if(inputController.checkBoxIsChecked){
            [inputController uncheckCheckbox];
        }
        if(outputController.checkBoxIsChecked){
            _outputConfig = _inputConfig;
            outputController.config = _outputConfig.copy;
            [outputController selectFormatByConfig];
        }
        BOOL didReload = [self reloadDataWithError:&outError];
        if (!didReload) {
            [self displayError:outError];
        }
    }else{
        _outputConfig = formatViewController.config;
    }
    [self.tableView reloadData];
}

-(void)useInputConfig:(TTFormatViewController *)formatViewController {
    formatViewController.config = _inputConfig.copy;
}

-(void)useFirstRowAsHeader:(TTFormatViewController *)formatViewController {
    if(formatViewController.checkBoxIsChecked){
        int i = 0;
        for(NSTableColumn *col in self.tableView.tableColumns){
            col.title = firstRow[i++];
        }
        [_data removeObjectAtIndex:0];
    }else{
        [self updateTableColumnsNames];
        [_data insertObject:firstRow.copy atIndex:0];
    }
    [self.tableView reloadData];
}

-(void)revertEditing{
    while([self.undoManager canUndo]){
        [self.undoManager undo];
    }
    [self.undoManager removeAllActions];
    edited = NO;
}

-(BOOL)reloadDataWithError:(NSError**)error {
    _maxColumnNumber = 1;
    [_data removeAllObjects];
    
    NSError *outError;
    CSVReader *reader = [[CSVReader alloc ]initWithData:savedData configuration: _inputConfig];
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
    [self initFirstRow];
    return YES;
}

-(void)dataGotEdited {
    if(!newFile && !edited){
        edited = YES;
        [inputController showRevertMessage];
        [self.splitView layoutSubtreeIfNeeded];
    }
    
    if([self.tableView selectedColumn] != -1){
        [self.tableView scrollColumnToVisible: [[self.tableView selectedColumnIndexes] firstIndex]];
    }else if([self.tableView selectedRow] != -1){
        [self.tableView scrollRowToVisible:[[self.tableView selectedRowIndexes] firstIndex]];
    }
}

#pragma mark - copy,paste,delete

-(IBAction)copy:(id)sender {
    if([self.tableView selectedRow] != -1){
        [self copyRowIndexes:[self.tableView selectedRowIndexes]];
    }else if([self.tableView selectedColumn] != -1){
        [self copyColumnIndexes:[self.tableView selectedColumnIndexes]];
    }else{
        NSBeep();
    }
    return;
}

-(void)copyRowIndexes:(NSIndexSet *)rowIndexes {
    NSMutableString *copyString = [NSMutableString string];
    
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSMutableString *rowString = [NSMutableString string];
        NSArray *row = _data[idx];
        for(NSString *columnId in [self getColumnsOrder]) {
            NSString *cellValue;
            if([row[columnId.integerValue] isKindOfClass:[NSDecimalNumber class]]){
                cellValue = [row[columnId.integerValue] descriptionWithLocale:[NSLocale currentLocale]];
            }else{
                cellValue = row[columnId.integerValue];
            }
            [self appendCell:cellValue toString:rowString];
        }
        [rowString deleteCharactersInRange:NSMakeRange(rowString.length-1, 1)];
        [copyString appendString:rowString];
        [copyString appendString:@"\n"];
    }];
    [copyString deleteCharactersInRange:NSMakeRange(copyString.length-1, 1)];
    
    NSPasteboard *generalPasteboard = [NSPasteboard generalPasteboard];
    [generalPasteboard clearContents];
    [generalPasteboard writeObjects:@[copyString]];
}

-(void)copyColumnIndexes:(NSIndexSet *)columnIndexes {
    NSMutableString *copyString = [NSMutableString string];
    
    for(int i = 0; i < [self.tableView numberOfRows];i++){
        NSMutableString *rowString = [[NSMutableString alloc]init];
        NSArray *row = _data[i];
        [columnIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            NSUInteger columnIndex = ((NSTableColumn *)self.tableView.tableColumns[idx]).identifier.integerValue;
            NSString *cellValue;
            if([row[columnIndex] isKindOfClass:[NSDecimalNumber class]]){
                cellValue = [row[columnIndex] descriptionWithLocale:[NSLocale currentLocale]];
            }else{
                cellValue = row[columnIndex];
            }
            [self appendCell:cellValue toString:rowString];
        }];
        [rowString deleteCharactersInRange:NSMakeRange(rowString.length-1, 1)];
        [copyString appendString:rowString];
        [copyString appendString:@"\n"];
    }
    [copyString deleteCharactersInRange:NSMakeRange(copyString.length-1, 1)];
    
    NSPasteboard *generalPasteboard = [NSPasteboard generalPasteboard];
    [generalPasteboard clearContents];
    [generalPasteboard writeObjects:@[copyString]];
}

-(void)appendCell:(NSString *)cell toString:(NSMutableString *)rowString {
    NSMutableString *cellValue = cell.mutableCopy;
    [cellValue replaceOccurrencesOfString:@"\t" withString:@" " options:0 range:NSMakeRange(0,cellValue.length)];
    [cellValue replaceOccurrencesOfString:@"\n" withString:@" " options:0 range:NSMakeRange(0,cellValue.length)];
    [rowString appendString:cellValue];
    [rowString appendString:@"\t"];
}

-(IBAction)paste:(id)sender {
    long toInsertIndex;
    if([self.tableView selectedRow] == -1){
        toInsertIndex = [self.tableView numberOfRows];
    } else {
        NSIndexSet *selectedRowIndexes = [self.tableView selectedRowIndexes];
        toInsertIndex = [selectedRowIndexes lastIndex] > [selectedRowIndexes firstIndex] ? [selectedRowIndexes lastIndex] + 1 : [selectedRowIndexes firstIndex] + 1;
    }
    long firstIndex = toInsertIndex;
    
    NSArray *classes = [[NSArray alloc]initWithObjects:[NSString class], nil];
    NSDictionary *options = [NSDictionary dictionary];
    NSPasteboard *generalPasteboard = [NSPasteboard generalPasteboard];
    NSArray *toInsert = [generalPasteboard readObjectsForClasses:classes options:options];
    CSVReader *reader = [[CSVReader alloc]initWithString:[toInsert lastObject] configuration:_inputConfig];
    
    while(![reader isAtEnd]) {
        NSArray *oneReadLine = [reader readLineForPastingTo:[self getColumnsOrder] maxColumnIndex:_maxColumnNumber];
        
        for(long i = _maxColumnNumber; i < oneReadLine.count;i++){
            [self addColumnAtIndex:self.tableView.tableColumns.count];
        }
        
        [_data insertObject:oneReadLine atIndex:toInsertIndex];
        toInsertIndex++;
    }
    [self.tableView reloadData];
    
    NSIndexSet *toSelectRowIndexes = [[NSIndexSet alloc]initWithIndexesInRange:NSMakeRange(firstIndex, toInsertIndex-firstIndex)];
    [self.tableView selectRowIndexes:toSelectRowIndexes byExtendingSelection:NO];
    [[self.undoManager prepareWithInvocationTarget:self] deleteRowsAtIndexes:toSelectRowIndexes];
    [self.undoManager setActionName:@"Paste Data"];
    [self dataGotEdited];
}

-(IBAction)delete:(id)sender {
    long selectedIndex = [self.tableView selectedRow];
    if(selectedIndex == -1){
        selectedIndex = [self.tableView selectedColumn];
        if(selectedIndex == -1) {
            NSBeep();
            return;
        }
        NSIndexSet *columnIndexes = [self.tableView selectedColumnIndexes];
        [self deleteColumnsAtIndexes:columnIndexes];
        [self.undoManager setActionName:@"Delete Column(s)"];
    }else{
        NSIndexSet *rowIndexes = [self.tableView selectedRowIndexes];
        [self deleteRowsAtIndexes:rowIndexes];
        [self.undoManager setActionName:@"Delete Row(s)"];
    }
    [self dataGotEdited];
}

-(void)updateToolbarIcons {
    [self.toolBarButtonsAddColumn setImage:[ToolbarIcons imageOfAddLeftColumnIcon] forSegment:0];
    [self.toolBarButtonsAddColumn setImage:[ToolbarIcons imageOfAddRightColumnIcon] forSegment:1];
    NSSize addColumnSize = self.toolBarButtonsAddColumn.intrinsicContentSize;
    addColumnSize.height = 30;
    self.toolbarItemAddColumn.minSize = addColumnSize;
    self.toolbarItemAddColumn.maxSize = addColumnSize;
    [self.toolBarButtonsAddRow setImage:[ToolbarIcons imageOfAddRowAboveIcon] forSegment:0];
    [self.toolBarButtonsAddRow setImage:[ToolbarIcons imageOfAddRowBelowIcon] forSegment:1];
    NSSize addRowSize = self.toolBarButtonsAddColumn.intrinsicContentSize;
    addRowSize.height = 30;
    self.toolbarItemAddColumn.minSize = addRowSize;
    self.toolbarItemAddColumn.maxSize = addRowSize;
    self.toolBarButtonDeleteColumn.image = [ToolbarIcons imageOfDeleteColumnIcon];
    self.toolBarButtonDeleteRow.image = [ToolbarIcons imageOfDeleteRowIcon];
}


@end
