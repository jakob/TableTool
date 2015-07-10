//
//  CSVReader.m
//  Table Tool
//
//  Created by Andreas Aigner on 09.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import "CSVReader.h"

@interface CSVReader () {
    NSScanner *dataScanner;
    NSMutableCharacterSet *valueCharacterSet;
    BOOL atEnd;
}

@end

@implementation CSVReader

-(instancetype)initWithData:(NSData *)data {
    self = [super init];
    if(self) {
        _data = data;
        _columnSeparator = @",";
        _quoteCharacter = @"\"";
        _encoding = NSUTF8StringEncoding;
        _escapeCharacter = @"\\";
        atEnd = NO;
    }
    return self;
}

-(NSArray *)readLineWithError:(NSError *__autoreleasing *)outError {
    if(!dataScanner){
        NSString *dataString = [[NSString alloc] initWithData:_data encoding:_encoding];
        if(dataString == nil) {
            if(outError != NULL) {
                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:1 userInfo: @{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"Try specifiying a different enocindg"}];
            }
            return nil;
        }
        dataScanner = [NSScanner scannerWithString:dataString];
        dataScanner.caseSensitive = YES;
        dataScanner.charactersToBeSkipped = nil;
        
        valueCharacterSet = [[NSCharacterSet newlineCharacterSet] invertedSet].mutableCopy;
        [valueCharacterSet removeCharactersInString:_columnSeparator];
    }
  

    NSMutableArray *rowArray = [[NSMutableArray alloc]init];
    for(;;) {
        BOOL didScanQuote = [dataScanner scanString:_quoteCharacter intoString:NULL];
        if(didScanQuote){
            NSString *scannedString;
            BOOL didScan = [dataScanner scanUpToString:_quoteCharacter intoString:&scannedString];
            if(didScan){
                [rowArray addObject:scannedString];
            } else {
                [rowArray addObject:@""];
            }
            BOOL didScanClosingQuote = [dataScanner scanString:_quoteCharacter intoString:NULL];
        }else{
            NSString *scannedString;
            BOOL didScanValue = [dataScanner scanCharactersFromSet:valueCharacterSet intoString:&scannedString];
            if(didScanValue){
                [rowArray addObject:scannedString];
            } else {
                [rowArray addObject:@""];
            }
        }
        BOOL didScanNewLine = [dataScanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
        if(didScanNewLine) {
            break;
        }
        BOOL didScanColumnSeparator = [dataScanner scanString:_columnSeparator intoString:NULL];
        if(!didScanColumnSeparator){
            atEnd = YES;
            break;
        }
    }
    
    return rowArray;
}

-(BOOL)isAtEnd {
    return atEnd;
}

@end
