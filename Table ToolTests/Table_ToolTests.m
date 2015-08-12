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
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testReadCommaSeparatedCSVFile {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Test Documents/comma-separated" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.quoteCharacter = @"";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(![reader isAtEnd]){
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
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Test Documents/semicolon-separated" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.columnSeparator = @";";
    config.decimalMark = @",";
    config.quoteCharacter = @"";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(![reader isAtEnd]){
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
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Test Documents/comma-separated-quote" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.decimalMark = @",";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(![reader isAtEnd]){
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
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Test Documents/quote-quote-escape" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(![reader isAtEnd]){
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
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Test Documents/quote-backslash-escape" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.escapeCharacter = @"\\";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(![reader isAtEnd]){
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

- (void)testReadCSVFileShouldGetErrorCode1 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Test Documents/invalid-encoding" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(![reader isAtEnd]){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
    }
    XCTAssertTrue(error.code == 1, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileShouldGetErrorCode2 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Test Documents/missing-quote" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(![reader isAtEnd]){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        }
    XCTAssertTrue(error.code == 2, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileShouldGetErrorCode3 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Test Documents/invalid-quote" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.quoteCharacter = @"";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(![reader isAtEnd]){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
    }
    XCTAssertTrue(error.code == 3, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadUnquotedCSVFile {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-doc-unquoted" withExtension:@"csv"];
    config.quoteCharacter = @"";
    [self measureBlock:^{
        NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
        CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
        while(![reader isAtEnd]){
            NSArray *line = [reader readLineWithError:NULL];
            XCTAssertEqual(line.count, 12);
            XCTAssertNotNil(line, "CSVReader should return object.");
            count++;
        }
        XCTAssertEqual(count, 987, "Should have read 987 lines.");
        count = 0;
    }];
}

- (void)testReadQuotedCSVFile {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-doc-quoted" withExtension:@"csv"];
    [self measureBlock:^{
        NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
        CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
        while(![reader isAtEnd]){
            NSArray *line = [reader readLineWithError:NULL];
            XCTAssertEqual(line.count, 11);
            XCTAssertNotNil(line, "CSVReader should return object.");
            count++;
        }
        XCTAssertEqual(count, 1002, "Should have read 1002 lines.");
        count = 0;
    }];
}

@end
