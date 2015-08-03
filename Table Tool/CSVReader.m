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
    BOOL skipQuotes;
    NSRegularExpression *regex;
    NSString *errorCode1;
    NSString *errorCode2;
    NSString *errorCode3;
}

@end


@implementation CSVReader

-(instancetype)initWithData:(NSData *)data configuration:(CSVConfiguration *)config{
    self = [super init];
    if(self) {
        _data = data;
        [self initVariables:config];
    }
    return self;
}

-(instancetype)initWithString:(NSString *)dataString configuration:(CSVConfiguration *)config{
    self = [super init];
    if(self) {
        _dataString = dataString;
        [self initVariables:config];
    }
    return self;
}

-(void)initVariables:(CSVConfiguration *)config{
    _config = config.copy;
    atEnd = NO;
    errorCode1 = @"Try specifying a different encoding.";
    errorCode2 = @"Try specifying a different separator, quote or escape character.";
    errorCode3 = errorCode2;
}


-(BOOL)initScannerWithError:(NSError **)outError skipQuotes:(BOOL)skip{
    if(!dataScanner){
        
        NSString *dataString = [NSString alloc];
        if(!_data){
            dataString = _dataString;
            skipQuotes = YES;
            _config.columnSeparator = @"\t";
            _config.decimalMark = [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator];
        }else{
            dataString = [[NSString alloc] initWithData:_data encoding:_config.encoding];
        }
        
        if(dataString == nil) {
            if(outError != NULL) {
                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:1 userInfo: @{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:errorCode1}];
            }
            return NO;
        }
        dataScanner = [NSScanner scannerWithString:dataString];
        dataScanner.caseSensitive = YES;
        dataScanner.charactersToBeSkipped = nil;
        
        quoteEndedCharacterSet = [NSCharacterSet newlineCharacterSet].mutableCopy;
        [quoteEndedCharacterSet addCharactersInString:_config.columnSeparator];
        valueCharacterSet = [quoteEndedCharacterSet invertedSet].mutableCopy;
        quoteAndEscapeSet = [[NSMutableCharacterSet alloc]init];
        [quoteAndEscapeSet addCharactersInString:_config.quoteCharacter];
        [quoteAndEscapeSet addCharactersInString:_config.escapeCharacter];
        
        regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"^\\s*[+-]?(\\d+\\%@?\\d*|\\d*\\%@?\\d+)([eE][+-]?\\d+)?\\s*$",_config.decimalMark,_config.decimalMark] options:0 error:NULL];
    }
    
    return YES;
}

-(NSArray *)readLineWithError:(NSError *__autoreleasing *)outError {
    
    NSError *scannerError = nil;
    BOOL didInitializeScanner = [self initScannerWithError:&scannerError skipQuotes:NO];
    if(!didInitializeScanner) {
        if(outError){
            *outError = scannerError;
        }
        return nil;
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
        
        if([regex numberOfMatchesInString:scannedString options:0 range:NSMakeRange(0, [scannedString length])] == 1){
            [rowArray addObject:[NSDecimalNumber decimalNumberWithString:scannedString locale:@{NSLocaleDecimalSeparator:_config.decimalMark}]];
        }else{
            [rowArray addObject:scannedString];
        }
        
        if(!dataScanner.atEnd){
            BOOL didScanNewLine = [[NSCharacterSet newlineCharacterSet] characterIsMember:[dataScanner.string characterAtIndex:dataScanner.scanLocation]];
            if(didScanNewLine) {
                dataScanner.scanLocation++;
                break;
            }
        }
        
        BOOL didScanColumnSeparator = [dataScanner scanString:_config.columnSeparator intoString:NULL];
        if(!didScanColumnSeparator){
            atEnd = YES;
            break;
        }
    }
    
    return rowArray;
}

-(NSArray *)readLineForPastingTo:(NSArray *)tableColumnsOrder maxColumnIndex:(long)maxColumnNumber {
    [self initScannerWithError:NULL skipQuotes:YES];
    
    NSMutableArray *rowArray = [[NSMutableArray alloc]init];
    for(int i = 0; i < maxColumnNumber; i++){
        [rowArray addObject:@""];
    }
    
    for(int i = 0;;i++) {
        NSString *scannedString = nil;
        BOOL scannedValueIsNumber = NO;
        
        [self scanUnquotedValueIntoString:&scannedString error:NULL];
        if([regex numberOfMatchesInString:scannedString options:0 range:NSMakeRange(0, [scannedString length])] == 1){
            scannedValueIsNumber = YES;
        }
        
        if(tableColumnsOrder.count > i){
            if(scannedValueIsNumber){
                [rowArray replaceObjectAtIndex:[tableColumnsOrder[i] integerValue] withObject:[NSDecimalNumber decimalNumberWithString:scannedString locale:@{NSLocaleDecimalSeparator:_config.decimalMark}]];
            }else{
                [rowArray replaceObjectAtIndex:[tableColumnsOrder[i] integerValue] withObject:scannedString];
            }
        } else {
            if(scannedValueIsNumber){
                [rowArray addObject:[NSDecimalNumber decimalNumberWithString:scannedString locale:@{NSLocaleDecimalSeparator:_config.decimalMark}]];
            }else{
                [rowArray addObject:scannedString];
            }
        }
        
        if(!dataScanner.atEnd){
            BOOL didScanNewLine = [[NSCharacterSet newlineCharacterSet] characterIsMember:[dataScanner.string characterAtIndex:dataScanner.scanLocation]];
            if(didScanNewLine) {
                dataScanner.scanLocation++;
                break;
            }
        }
        
        BOOL didScanColumnSeparator = [dataScanner scanString:_config.columnSeparator intoString:NULL];
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
    
    if([dataScanner scanString:_config.quoteCharacter intoString:NULL]) {
        
        NSString *partialString;
        NSMutableString *temporaryString = [[NSMutableString alloc] init];
        
        if([_config.escapeCharacter isEqualToString:_config.quoteCharacter]){
            while(!dataScanner.atEnd) {
                char charAtScannerIndex = [dataScanner.string characterAtIndex:dataScanner.scanLocation];
                if([_config.quoteCharacter isEqualToString:[NSString stringWithFormat:@"%c",charAtScannerIndex]]){
                    [dataScanner scanString:_config.quoteCharacter intoString:NULL];
                    if(!dataScanner.atEnd){
                        charAtScannerIndex = [dataScanner.string characterAtIndex:dataScanner.scanLocation];
                        if([_config.quoteCharacter isEqualToString:[NSString stringWithFormat:@"%c",charAtScannerIndex]]){
                            [temporaryString appendString:@"\""];
                            dataScanner.scanLocation++;
                            if(dataScanner.atEnd){
                                if(outError != NULL) {
                                    *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:errorCode2}];
                                }
                                return NO;
                            }
                        }else if([quoteEndedCharacterSet characterIsMember:charAtScannerIndex]){
                            break;
                        }else{
                            if(outError != NULL) {
                                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:errorCode2}];
                            }
                            return NO;
                        }
                    }
                }else{
                    BOOL didScan = [dataScanner scanUpToString:_config.quoteCharacter intoString:&partialString];
                    if(didScan){
                        if(dataScanner.atEnd || ![_config.quoteCharacter isEqualToString:[NSString stringWithFormat:@"%c",[dataScanner.string characterAtIndex:dataScanner.scanLocation]]]){
                            if(outError != NULL) {
                                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:errorCode2}];
                            }
                            return NO;
                        }
                        [temporaryString appendString:partialString];
                    }else{
                        [temporaryString appendString:@""];
                    }
                }
            }
        }else{
            while(!dataScanner.atEnd){
                BOOL didScan = [dataScanner scanUpToCharactersFromSet:quoteAndEscapeSet intoString:&partialString];
                if(didScan){
                    [temporaryString appendString:partialString];
                }
                didScan = [dataScanner scanString:_config.escapeCharacter intoString:NULL];
                if(didScan){
                    if(dataScanner.atEnd){
                        if(outError != NULL) {
                            *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:errorCode2}];
                        }
                        return NO;
                    }
                    [temporaryString appendString:[dataScanner.string substringWithRange:NSMakeRange(dataScanner.scanLocation, 1)]];
                    dataScanner.scanLocation++;
                }
                didScan = [dataScanner scanString:_config.quoteCharacter intoString:NULL];
                if(didScan){
                    if(dataScanner.atEnd || [quoteEndedCharacterSet characterIsMember:[dataScanner.string characterAtIndex:dataScanner.scanLocation]]){
                        *scannedString = temporaryString;
                        return YES;
                    }
                    if(outError != NULL) {
                        *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:errorCode2}];
                    }
                    return NO;
                    
                }
            }
            if(outError != NULL) {
                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:errorCode2}];
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
        if([temporaryString.copy rangeOfString:_config.quoteCharacter].location != NSNotFound && !skipQuotes){
            if(outError != NULL) {
                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:errorCode3}];
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

