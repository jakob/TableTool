//
//  Document_UI_Tests.m
//  Table Tool
//
//  Created by Martin Köhler on 18.06.17.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSFileHandle+TempFile.h"

@interface DocumentTests : XCTestCase
{
    XCUIApplication *app;
    NSSpeechSynthesizer *speechSynthesizer;
}
@end

@implementation DocumentTests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    
    app = [[XCUIApplication alloc] init];
    [app launch];
    
    for (NSString *voiceIdentifier in [NSSpeechSynthesizer availableVoices]) {
        NSString *voiceLocaleIdentifier = [[NSSpeechSynthesizer attributesForVoice:voiceIdentifier] objectForKey:NSVoiceLocaleIdentifier];
        NSLog(@"%@ speaks %@", voiceIdentifier, voiceLocaleIdentifier);
        
        if ([voiceLocaleIdentifier containsString:@"en_US"]) {
            NSLog(@"Using, %@ speaks %@", voiceIdentifier, voiceLocaleIdentifier);
            
            speechSynthesizer = [[NSSpeechSynthesizer alloc] initWithVoice:voiceIdentifier];
            break;
        }
    }
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run.
    // The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    [self removeTempFiles];
}

- (void)speak:(NSString *)text
{
    [self waitUntilFinishedSpeaking];
    [speechSynthesizer startSpeakingString:text];
}

- (void)waitUntilFinishedSpeaking
{
    // NOTE: potentially better use async delegate, but to keep it simple as it's just a test case, for now polling every second
    while ([NSSpeechSynthesizer isAnyApplicationSpeaking]) {
        [NSThread sleepForTimeInterval:1.0];
    }
}

- (void)closeAllDocuments
{
    [self speak:@"Closing all documents from previous sessions"];
    
    XCUIElementQuery *menuBarsQuery = app.menuBars;
    XCUIElement *fileMenuBarItem = menuBarsQuery.menuBarItems[@"File"];
    [fileMenuBarItem click];
    
    XCUIElement *closeMenuItem = menuBarsQuery.menuItems[@"Close"];
    while ([closeMenuItem isEnabled]) {
        [closeMenuItem click];
        [fileMenuBarItem click];
    }
}

- (void)openDocumentAtPath:(NSString *)absoluteDocumentPath
{
    [self speak:@"Opening Test Document"];
    
    XCUIElementQuery *menuBarsQuery = app.menuBars;
    XCUIElement *openMenuItem = menuBarsQuery.menuItems[@"Open…"];
    [openMenuItem click];
    
    XCUIElement *openDialog = app.dialogs[@"Open"];
    NSString *gKey = @"g";
    XCUIKeyModifierFlags cmdAndShiftModifierFlags = XCUIKeyModifierCommand | XCUIKeyModifierShift;
    [openDialog typeKey:gKey modifierFlags:cmdAndShiftModifierFlags];
    
    XCUIElementQuery *textFieldsQuery = openDialog.sheets.textFields;
    XCUIElement *pathTextField = [textFieldsQuery element];
    
    [pathTextField typeText:absoluteDocumentPath];
    [pathTextField typeText:@"\n"];
    
    [openDialog typeText:@"\n"]; // confirm open of file
}

- (void)clickToolbarItemWithIdentifier:(NSString *)toolbarItemID
                      inDocumentWindow:(XCUIElement *)docWindow
{
    [self speak:[NSString stringWithFormat:@"Clicking toolbar item '%@'",toolbarItemID,nil]];
    
    XCUIElementQuery *toolbarGroupQuery = [docWindow.toolbars.groups containingType:XCUIElementTypeStaticText identifier:toolbarItemID];
    XCUIElement *toolbarItemButton = [[toolbarGroupQuery descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1];
    [toolbarItemButton click];
}

- (void)revertToActionMatchingPredicateWithFormat:(NSString *)predicateFormat
                                 inDocumentWindow:(XCUIElement *)docWindow
{
    [self speak:@"Reverting document"];
    
    XCUIElementQuery *menuBarsQuery = app.menuBars;
    [menuBarsQuery.menuBarItems[@"File"] click];
    
    XCUIElement *revertMenuItem = menuBarsQuery.menuItems[@"Revert To"];
    [revertMenuItem click];
    
    // NOTE: substring search necessary, because the menu item will be something like .menuItems[@"Last Opened \U2014 Heute, 12:35"]
    XCUIElement *revertToLastOpenedMenuItem = [revertMenuItem.menuItems elementMatchingPredicate:[NSPredicate predicateWithFormat:predicateFormat]];
    [revertToLastOpenedMenuItem click];
    
    [docWindow.sheets[@"alert"].buttons[@"Revert"] click];
}

- (void)assertTableCellValue:(NSString *)expectedValue
                         row:(NSUInteger)row
                      column:(NSUInteger)column
            inDocumentWindow:(XCUIElement *)docWindow
{
    [self speak:[NSString stringWithFormat:@"Asserting table cell in row %ld, column %ld to have the expected value '%@'", row, column, expectedValue, nil]];
    
    XCUIElement *textField = [[[[docWindow.tables childrenMatchingType:XCUIElementTypeTableRow] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeTextField] elementBoundByIndex:0];
    [textField click];
    
    [self waitUntilFinishedSpeaking];
    XCTAssertEqualObjects(expectedValue, [textField value]);
}

-(void)removeTempFiles
{
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *cacheFiles = [fileManager contentsOfDirectoryAtPath:tmpDirectory error:&error];
    for (NSString *file in cacheFiles) {
        error = nil;
        [fileManager removeItemAtPath:[tmpDirectory stringByAppendingPathComponent:file] error:&error];
    }
}

- (void)testRestoreDocumentWithTableHeaderDetection
{
    //
    // This test case is a regression test which reproduces a defect (2017.06.18)
    //
    // Defect Summary: Autodetected table header is lost after restoring an older version of the document
    //
    // Steps to reproduce:
    //     (1) open a CSV with an autodetectable table header
    //     (2) Assert: table header is detected
    //     (3) append a table row without saving the document
    //     (4) click main menu "File" > Restore to the opened version
    //     (5) Assert: table header is detected   (Defect: this assertion failed!)
    //
    
    [self closeAllDocuments];
    
    NSString *testData = @"header1,header2\n"
                          "1,2";
    
    NSMutableString *outPath = [NSMutableString string];
    NSError *error = nil;
    NSString *testCSVFileName = @"test-CSV-with-header";
    NSString *extension = @"csv";
    NSFileHandle *tmpFile = [NSFileHandle tempFileForTestClass:[self className]
                                                      selector:NSStringFromSelector(_cmd)
                                      fileNameWithoutExtension:testCSVFileName
                                                     extension:extension
                                                       getPath:outPath
                                                         error:&error];
    XCTAssertNil(error);
    if (error != nil) {
        return; // test failure
    }
    
    [tmpFile truncateFileAtOffset:0];
    [tmpFile writeData:[testData dataUsingEncoding:NSUTF8StringEncoding]];
    [tmpFile closeFile];
        
    [self openDocumentAtPath:outPath];

    NSString *windowTitle = [outPath lastPathComponent];
    XCUIElement *docWindow = app.windows[windowTitle];
    
    [self clickToolbarItemWithIdentifier:@"Add Row" inDocumentWindow:docWindow];
    
    [self revertToActionMatchingPredicateWithFormat:@"title contains[cd] \"Last Opened\"" inDocumentWindow:docWindow];
    
    // NOTE: if the header detection would have worked, row cell (0, 0) must be '1', but not 'header1'
    [self assertTableCellValue:@"1" row:0 column:0 inDocumentWindow:docWindow];
}

@end
