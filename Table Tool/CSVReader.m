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
    NSString *workString;
    NSMutableCharacterSet *valueCharacterSet;
    NSMutableCharacterSet *quoteEndedCharacterSet;
    NSMutableCharacterSet *quoteAndEscapeSet;
    BOOL atEnd;
    BOOL forPasting;
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
            forPasting = YES;
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
        
        workString = dataScanner.string;
        
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
    
    while(!atEnd){
        NSString *scannedString = nil;
        NSError *scanError = nil;
        
        BOOL didScan = NO;
        if(![_config.quoteCharacter isEqualToString:@""]){
            didScan = [self scanQuotedValueIntoString:&scannedString error:&scanError];
        }
        
        if((!didScan && scanError == nil)){
            didScan = [self scanUnquotedValueIntoString:&scannedString error:&scanError];
        }
        
        if(!didScan) {
            if(outError){
                *outError = scanError;
            }
            return nil;
        }
        
        if(scannedString.length > 0 && [regex numberOfMatchesInString:scannedString options:0 range:NSMakeRange(0, [scannedString length])] == 1){
            [rowArray addObject:[NSDecimalNumber decimalNumberWithString:scannedString locale:@{NSLocaleDecimalSeparator:_config.decimalMark}]];
        }else{
            [rowArray addObject:scannedString];
        }
        
        if(dataScanner.atEnd){
            atEnd = YES;
            break;
        }
        
        BOOL didScanNewLine = [[NSCharacterSet newlineCharacterSet] characterIsMember:[dataScanner.string characterAtIndex:dataScanner.scanLocation]];
        if(didScanNewLine) {
            dataScanner.scanLocation++;
            break;
        }
        
        BOOL didScanColumnSeparator = [dataScanner scanString:_config.columnSeparator intoString:NULL];
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
    
    if(dataScanner.atEnd) {
        *scannedString = @"";
        return YES;
    }
    
    if([workString characterAtIndex:dataScanner.scanLocation] != '\"'){
        return NO;
    }
    
    dataScanner.scanLocation++;
    
    NSString *partialString;
    NSMutableString *temporaryString = [[NSMutableString alloc] init];
    
    if([_config.escapeCharacter isEqualToString:_config.quoteCharacter]){
        while(!dataScanner.atEnd){
            
            while(!dataScanner.atEnd && [workString characterAtIndex:dataScanner.scanLocation] != [_config.escapeCharacter characterAtIndex:0]) {
                [temporaryString appendString:[workString substringWithRange:NSMakeRange(dataScanner.scanLocation, 1)]];
                dataScanner.scanLocation++;
            }
            
            if(dataScanner.atEnd) {
                if(outError != NULL) {
                    *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:errorCode2}];
                }
                return NO;
            }
            
            dataScanner.scanLocation++;
            if(workString.length >= dataScanner.scanLocation+1){
                if([quoteEndedCharacterSet characterIsMember:[workString characterAtIndex:dataScanner.scanLocation]]) {
                    *scannedString = temporaryString;
                    [self checkForCRLF];
                    return YES;
                }
                [temporaryString appendString:[workString substringWithRange:NSMakeRange(dataScanner.scanLocation,1)]];
                if(dataScanner.atEnd) {
                    if(outError != NULL) {
                        *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:errorCode2}];
                    }
                    return NO;
                }
                dataScanner.scanLocation++;
            }else{
                *scannedString = temporaryString;
                [self checkForCRLF];
                return YES;
            }
        }
        if(outError != NULL) {
            *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:errorCode2}];
        }
        return NO;
    }
    
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

-(BOOL)scanUnquotedValueIntoString:(NSString **)scannedString error:(NSError **)outError{
    
    NSMutableString *temporaryString = [[NSMutableString alloc]initWithString:@""];
    while(!dataScanner.atEnd && ![quoteEndedCharacterSet characterIsMember:[workString characterAtIndex:dataScanner.scanLocation]]){
        if([workString characterAtIndex:dataScanner.scanLocation] == '\"' && !forPasting){
            if(outError != NULL) {
                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:errorCode3}];
            }
            return NO;
        }
        [temporaryString appendString:[workString substringWithRange:NSMakeRange(dataScanner.scanLocation, 1)]];
        dataScanner.scanLocation++;
    }
    *scannedString = temporaryString;
    [self checkForCRLF];
    return YES;
}

-(void)reset{
    dataScanner = nil;
}

-(void)checkForCRLF{
    if(dataScanner.scanLocation>dataScanner.string.length-2) return;
    if([dataScanner.string characterAtIndex:dataScanner.scanLocation] == '\r' && [dataScanner.string characterAtIndex:dataScanner.scanLocation+1] == '\n'){
        dataScanner.scanLocation++;
    }
}

@end

