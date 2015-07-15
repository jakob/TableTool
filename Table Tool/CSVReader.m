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
    NSMutableCharacterSet *quoteEndedCharacterSet;
    NSMutableCharacterSet *quoteAndEscapeSet;
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
                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:1 userInfo: @{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"Try specifiying a different encoding"}];
            }
            return nil;
        }
        dataScanner = [NSScanner scannerWithString:dataString];
        dataScanner.caseSensitive = YES;
        dataScanner.charactersToBeSkipped = nil;
        
        quoteEndedCharacterSet = [NSCharacterSet newlineCharacterSet].mutableCopy;
        [quoteEndedCharacterSet addCharactersInString:_columnSeparator];
        valueCharacterSet = [quoteEndedCharacterSet invertedSet].mutableCopy;
        quoteAndEscapeSet = [[NSMutableCharacterSet alloc]init];
        [quoteAndEscapeSet addCharactersInString:_quoteCharacter];
        [quoteAndEscapeSet addCharactersInString:_escapeCharacter];
    }
    
    NSMutableArray *rowArray = [[NSMutableArray alloc]init];
    
    for(;;) {
        NSString *scannedString = nil;
        NSError *scanError = nil;
        
        BOOL didScan = [self scanQuotedValueIntoString:&scannedString error:&scanError];
        if(!didScan && scanError == nil){
            didScan = [self scanUnquotedValueIntoString:&scannedString error:&scanError];
        }
        if(!didScan) {
            if(outError){
                *outError = scanError;
            }
            return nil;
        }
        
        [rowArray addObject:scannedString];
        
        if(!dataScanner.atEnd){
            BOOL didScanNewLine = [[NSCharacterSet newlineCharacterSet] characterIsMember:[dataScanner.string characterAtIndex:dataScanner.scanLocation]];
            if(didScanNewLine) {
                dataScanner.scanLocation++;
                break;
            }
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

-(BOOL)scanQuotedValueIntoString:(NSString **)scannedString error:(NSError**)outError {
    
    if (outError) *outError = nil;
    
    if([dataScanner scanString:_quoteCharacter intoString:NULL]) {
        
        NSString *partialString;
        NSMutableString *temporaryString = [[NSMutableString alloc] init];
        
        if([_escapeCharacter isEqualToString:_quoteCharacter]){
            while(!dataScanner.atEnd) {
                BOOL didScan = 1;
                /*
                char charAtScannerIndex = [dataScanner.string characterAtIndex:dataScanner.scanLocation];
                if([_quoteCharacter isEqualToString:[NSString stringWithFormat:@"%c",charAtScannerIndex]]){
                    [dataScanner scanString:_quoteCharacter intoString:NULL];
                    if(!dataScanner.atEnd){
                        charAtScannerIndex = [dataScanner.string characterAtIndex:dataScanner.scanLocation];
                        if([_quoteCharacter isEqualToString:[NSString stringWithFormat:@"%c",charAtScannerIndex]]){
                            [temporaryString appendString:@"\""];
                            dataScanner.scanLocation++;
                            if(dataScanner.atEnd){
                                if(outError != NULL) {
                                    *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"At some point there is a quote missing"}];
                                }
                                return NO;
                            }
                        }else if([quoteEndedCharacterSet characterIsMember:charAtScannerIndex]){
                            break;
                        }else{
                            if(outError != NULL) {
                                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"At some point there is a quote missing"}];
                            }
                            return NO;
                        }
                    }
                }else{
                    BOOL didScan = [dataScanner scanUpToString:_quoteCharacter intoString:&partialString];
                    if(didScan){
                        if(dataScanner.atEnd || !('"' == [dataScanner.string characterAtIndex:dataScanner.scanLocation])){
                            if(outError != NULL) {
                                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"At some point there is a quote missing"}];
                            }
                            return NO;
                        }
                        [temporaryString appendString:partialString];
                    }else{
                        [temporaryString appendString:@""];
                    }
                }*/
            }
        }else{
            while(!dataScanner.atEnd){
                BOOL didScan = [dataScanner scanUpToCharactersFromSet:quoteAndEscapeSet intoString:&partialString];
                if(didScan){
                    [temporaryString appendString:partialString];
                }
                didScan = [dataScanner scanString:_escapeCharacter intoString:NULL];
                if(didScan){
                    if(dataScanner.atEnd){
                        if(outError != NULL) {
                            *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"At some point there is a quote missing"}];
                        }
                        return NO;
                    }
                    [temporaryString appendString:[dataScanner.string substringWithRange:NSMakeRange(dataScanner.scanLocation, 1)]];
                    dataScanner.scanLocation++;
                }
                didScan = [dataScanner scanString:_quoteCharacter intoString:NULL];
                if(didScan){
                    if(dataScanner.atEnd || [quoteEndedCharacterSet characterIsMember:[dataScanner.string characterAtIndex:dataScanner.scanLocation]]){
                        *scannedString = temporaryString;
                        return YES;
                    }
                    if(outError != NULL) {
                        *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"At some point there is a quote missing"}];
                    }
                    return NO;
                    
                }
            }
            if(outError != NULL) {
                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"At some point there is a quote missing"}];
            }
            return NO;
        }
        *scannedString = temporaryString;
        return YES;
    }else{
        return NO;
    }
}

-(BOOL)scanUnquotedValueIntoString:(NSString **)scannedString error:(NSError **)outError{
    
    NSString *temporaryString;
    BOOL didScanValue = [dataScanner scanCharactersFromSet:valueCharacterSet intoString:&temporaryString];
    if(didScanValue){
        if([temporaryString.copy rangeOfString:_quoteCharacter].location != NSNotFound){
            if(outError != NULL) {
                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"A non-quote value is unacceptable due to at least one quote character in it"}];
            }
            return NO;
        }
        *scannedString = temporaryString;
    }else{
        *scannedString = @"";
    }
    return YES;
}

@end

