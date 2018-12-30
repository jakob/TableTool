//
//  Table_ToolTests.m
//  Table ToolTests
//
//  Created by Andreas Aigner on 06.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "CSVReader.h"
#import "CSVConfiguration.h"
#import "CSVHeuristic.h"

@interface Table_ToolTests : XCTestCase {
    int count;
    CSVConfiguration *config;
}

@end

@implementation Table_ToolTests

- (void)setUp {
    [super setUp];
    count = 0;
    config = [[CSVConfiguration alloc]init];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testReadCommaSeparatedCSVFile {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/comma-separated" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.quoteCharacter = @"";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:NULL];
        XCTAssertNotNil(line, "CSVReader should return object.");
        count++;
        XCTAssertEqual(line.count, 3, "Read line should have 3 objects.");
        if(count == 3){
            for(int i=0;i<3;i++){
                XCTAssertTrue([line[i] isKindOfClass:[NSDecimalNumber class]], "Last line should contain 3 decimal numbers.");
            }
        }
    }
    XCTAssertEqual(count, 3, "CSVReader should have read 3 lines.");
    XCTAssert(YES, @"Pass");
}

- (void)testReadSemicolonSeparatedCSVFile {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/semicolon-separated" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.columnSeparator = @";";
    config.decimalMark = @",";
    config.quoteCharacter = @"";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:NULL];
        XCTAssertNotNil(line, "CSVReader should return object.");
        count++;
        XCTAssertEqual(line.count, 3, "Read line should have 3 objects.");
        if(count == 3){
            for(int i=0;i<3;i++){
                XCTAssertTrue([line[i] isKindOfClass:[NSDecimalNumber class]], "Last line should contain 3 decimal numbers.");
            }
        }
    }
    XCTAssertEqual(count, 3, "CSVReader should have read 3 lines.");
    XCTAssert(YES, @"Pass");
}

- (void)testReadQuotedCommaSeparatedCSVFile {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/comma-separated-quote" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.decimalMark = @",";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:NULL];
        XCTAssertNotNil(line, "CSVReader should return object.");
        count++;
        XCTAssertEqual(line.count, 3, "Read line should have 3 objects.");
        if(count == 2 || count == 3){
            for(int i=0;i<3;i++){
                XCTAssertTrue([line[i] isKindOfClass:[NSDecimalNumber class]], @"Line should contain 3 decimal numbers.");
            }
        }
    }
    XCTAssertEqual(count, 3, "CSVReader should have read 3 lines.");
    XCTAssert(YES, @"Pass");
}

- (void)testReadQuotedCSVFileWithQuoteEscape {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/quote-quote-escape" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:NULL];
        XCTAssertNotNil(line, "CSVReader should return object.");
        count++;
        XCTAssertEqual(line.count, 2, "Read line should have 2 objects.");
        if(count == 2){
            XCTAssertTrue([line[0] isKindOfClass:[NSDecimalNumber class]], @"First object should decimal number.");
            XCTAssertFalse([line[1] isKindOfClass:[NSDecimalNumber class]], @"Second object should not be decimal number.");
        }
    }
    XCTAssertEqual(count, 2, "CSVReader should have read 2 lines.");
    XCTAssert(YES, @"Pass");
}

- (void)testReadQuotedCSVFileWithBackslashEscape {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/quote-backslash-escape" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.escapeCharacter = @"\\";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:NULL];
        XCTAssertNotNil(line, "CSVReader should return object.");
        count++;
        XCTAssertEqual(line.count, 2, "Read line should have 2 objects.");
        if(count == 2){
            XCTAssertTrue([line[0] isKindOfClass:[NSDecimalNumber class]], @"First object should decimal number.");
            XCTAssertFalse([line[1] isKindOfClass:[NSDecimalNumber class]], @"Second object should not be decimal number.");
        }
    }
    XCTAssertEqual(count, 2, "CSVReader should have read 2 lines.");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithInvalidEncoding_ShouldGetErrorCode1 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/invalid-encoding" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        XCTAssertNotNil(line, "CSVReader should return object.");
    }
    XCTAssertEqual(error.code, 1, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithMissingQuoteAtEnd_ShouldGetErrorCode2 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/missing-quote-atEnd" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        XCTAssertNil(line, "CSVReader should not return object.");
    }
    XCTAssertEqual(error.code, 2, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithMissingBackslashBeforeValue_ShouldGetErrorCode2 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/missing-backslash-beforeValue" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.escapeCharacter = @"\\";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        XCTAssertNil(line, "CSVReader should not return object.");
    }
    XCTAssertEqual(error.code, 2, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithMissingBackslashAfterValue_ShouldGetErrorCode2 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/missing-backslash-afterValue" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.escapeCharacter = @"\\";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        XCTAssertNil(line, "CSVReader should not return object.");
    }
    XCTAssertEqual(error.code, 2, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithMissingValueForBackslashInquote_ShouldGetErrorCode2 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/missing-value-for-backslash-inquote" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.escapeCharacter = @"\\";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        XCTAssertNil(line, "CSVReader should not return object.");
    }
    XCTAssertEqual(error.code, 2, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithMissingValueForeBackslashBeforeValue_ShouldGetErrorCode2 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/missing-value-for-backslash" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.escapeCharacter = @"\\";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        XCTAssertNil(line, "CSVReader should not return object.");
    }
    XCTAssertEqual(error.code, 2, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithQuoteInUnquotedValue_ShouldGetErrorCode3 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/quote-in-unquoted-value" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        XCTAssertNil(line, "CSVReader should not return object.");
    }
    XCTAssertEqual(error.code, 3, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithBlankLines {
	NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/blank-lines" withExtension:@"csv"];
	NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
	CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
	NSError *error = nil;
	NSUInteger numLines = 0;
	while([reader readLineWithError:&error]) {
		numLines++;
	}
	XCTAssertEqual(numLines, 6, "File should contain 6 rows.");
}



- (void)testHeuristicError1 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-comma-separated-people-1" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

- (void)testHeuristicError2 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-comma-separated-people-2" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

- (void)testHeuristicError3 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-comma-separated-places" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssert([config.quoteCharacter isEqual:@"\""], "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig1 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config1" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig2 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config2" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ';', "Column Separator should be ';'.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], ',', "Decimal Mark should be ','.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig3 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config3" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], '\t', "Column Separator should be '\t'.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig4 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config4" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], '\t', "Column Separator should be '\t'.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], ',', "Decimal Mark should be ','.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig5 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config5" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ';', "Column Separator should be ';'.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], ',', "Decimal Mark should be ','.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\\', "Escape character should be '\\'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig6 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config6" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssertTrue([config.quoteCharacter isEqualToString:@""], "Quote should be disabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig7 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config7" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ';', "Column Separator should be ';'.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], ',', "Decimal Mark should be ','.");
    XCTAssertTrue([config.quoteCharacter isEqualToString:@""], "Quote should be disabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig8 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config8" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], '\t', "Column Separator should be '\t'.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssertTrue([config.quoteCharacter isEqualToString:@""], "Quote should be disabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig9 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config9" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], '\t', "Column Separator should be '\t'.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], ',', "Decimal Mark should be ','.");
    XCTAssertTrue([config.quoteCharacter isEqualToString:@""], "Quote should be disabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig10 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config10" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\\', "Escape character should be '\\'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig11 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config11" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], ',', "Decimal Mark should be ','.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

- (void)testHeuristicNoHeaderBecauseOfNumber {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-first-row-with-number" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertFalse(config.firstRowAsHeader, "First row should not be header");
}

- (void)testHeuristicNoHeaderBecauseOfShorterLength {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-first-row-one-row-shorter" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertFalse(config.firstRowAsHeader, "First row should not be header");
}

- (void)testHeuristicNoHeaderBecauseOfLongerLength {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-first-row-longer" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertFalse(config.firstRowAsHeader, "First row should not be header");
}

- (void)testHeuristicChangeEncodingToWestern {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-no-utf-encoding" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat].config;
    XCTAssertEqual(config.encoding, NSWindowsCP1252StringEncoding, "Encoding should be Western");
}

- (void)testHeuristicGBK {
	NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-gbk" withExtension:@"csv"];
	NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
	CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
	heuristic.preferChineseEncoding = YES;
	config = [heuristic calculatePossibleFormat].config;
	XCTAssertEqual(config.encoding, CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000), "Encoding should be GBK");
}

- (void)testHeuristicIssue4Sample {
	NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/issue-4-sample" withExtension:@"csv"];
	NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
	CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
	config = [heuristic calculatePossibleFormat].config;
	XCTAssertEqual(config.encoding, NSMacOSRomanStringEncoding);
	XCTAssertEqualObjects(config.columnSeparator, @"\t");
	XCTAssertTrue(config.firstRowAsHeader);
}

- (void)testPerformanceReaderUnquotedValues {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-doc-unquoted" withExtension:@"csv"];
    config.quoteCharacter = @"";
    [self measureBlock:^{
        NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
        CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
        while(!reader.isAtEnd){
            NSArray *line = [reader readLineWithError:NULL];
            XCTAssertEqual(line.count, 12);
            XCTAssertNotNil(line, "CSVReader should return object.");
            count++;
        }
        XCTAssertEqual(count, 987, "Should have read 987 lines.");
        count = 0;
    }];
}

- (void)testPerformanceReaderQuotedValues {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-doc-quoted" withExtension:@"csv"];
    [self measureBlock:^{
        NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
        CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
        while(!reader.isAtEnd){
            NSArray *line = [reader readLineWithError:NULL];
            XCTAssertEqual(line.count, 11);
            XCTAssertNotNil(line, "CSVReader should return object.");
            count++;
        }
        XCTAssertEqual(count, 1002, "Should have read 1002 lines.");
        count = 0;
    }];
}

- (void)testPerformanceHeuristic {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-doc-quoted" withExtension:@"csv"];
    [self measureBlock:^{
        for(int i = 0;i < 10; i++){
            NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
            CSVHeuristic *heuristic = [[CSVHeuristic alloc]initWithData:testData];
            config = [heuristic calculatePossibleFormat].config;
            XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
            XCTAssertEqual([config.decimalMark characterAtIndex:0], ',', "Decimal Mark should be ','.");
            XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
            XCTAssertEqual(config.firstRowAsHeader, YES, "First row should be header.");
            XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
            config = nil;
        }
    }];
    
}

@end
