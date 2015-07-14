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
        _escapeCharacter = @"\"";
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
    }
    
    NSMutableArray *rowArray = [[NSMutableArray alloc]init];
    
    for(;;) {
        NSString *scannedString;
        BOOL didScanQuote = [self scanQuotedValueIntoString:&scannedString error:outError];
        
        if(!didScanQuote){
            [self scanUnquotedValueIntoString:&scannedString];
        }
        if(scannedString == nil) {
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
            BOOL doubleQuoteCharacter = NO;
            while(!dataScanner.atEnd) {
                if('"' == [dataScanner.string characterAtIndex:dataScanner.scanLocation]){
                    [dataScanner scanString:_quoteCharacter intoString:NULL];
                    if(!dataScanner.atEnd){
                        if('"' == [dataScanner.string characterAtIndex:dataScanner.scanLocation]){
                            [temporaryString appendString:@"\""];
                            [dataScanner scanString:_quoteCharacter intoString:NULL];
                            doubleQuoteCharacter = YES;
                        }else{
                            doubleQuoteCharacter = NO;
                        }
                    }
                }else if([quoteEndedCharacterSet characterIsMember:[dataScanner.string characterAtIndex:dataScanner.scanLocation]]){
                    if(doubleQuoteCharacter && [dataScanner scanString:_columnSeparator intoString:&partialString]){
                        [temporaryString appendString:partialString];
                        doubleQuoteCharacter = NO;
                    }else{
                        break;
                    }
                }else{
                    BOOL didScan = [dataScanner scanUpToString:_quoteCharacter intoString:&partialString];
                    if(didScan){
                        if(dataScanner.atEnd || !('"' == [dataScanner.string characterAtIndex:dataScanner.scanLocation]) || [partialString rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound){
                            if(outError != NULL) {
                                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"At some point there is a quote missing"}];
                            }
                            return YES;
                        }
                        [temporaryString appendString:partialString];
                    }else{
                        [temporaryString appendString:@""];
                    }
                }
            }
        }else{
            while(!dataScanner.atEnd){
                BOOL didScan = [dataScanner scanUpToString:_quoteCharacter intoString:&partialString];
                if(didScan){
                    [temporaryString appendString:partialString];
                    if(!('\\' == [dataScanner.string characterAtIndex:dataScanner.scanLocation-1])){
                        dataScanner.scanLocation++;
                        break;
                    }else{
                        [temporaryString appendString:@"\""];
                        dataScanner.scanLocation++;
                    }
                }else{
                    if(dataScanner.atEnd){
                        if(outError != NULL) {
                            *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"At some point there is a quote missing"}];
                        }
                        return YES;
                    }else{
                        dataScanner.scanLocation++;
                        break;
                    }
                }
            }
            partialString = temporaryString.copy;
            partialString = [partialString stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
            partialString = [partialString stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
            temporaryString = partialString.mutableCopy;
        }
        *scannedString = temporaryString;
        return YES;
    }else{
        return NO;
    }
}

-(void)scanUnquotedValueIntoString:(NSString **)scannedString {
    
    NSString *temporaryString;
    BOOL didScanValue = [dataScanner scanCharactersFromSet:valueCharacterSet intoString:&temporaryString];
    if(didScanValue){
        *scannedString = temporaryString;
    }else{
        *scannedString = @"";
    }
    
    return;
}

@end

