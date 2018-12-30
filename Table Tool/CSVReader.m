//
//  CSVReader.m
//  Table Tool
//
//  Created by Andreas Aigner on 09.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import "CSVReader.h"

@interface CSVScanner : NSObject
+ (instancetype)scannerWithString:(NSString *)string;

@property (nonatomic, copy) NSString *string;
@property (nonatomic) NSUInteger stringLength;
@property (nonatomic) NSUInteger scanLocation;
@property (nonatomic, readonly, getter=isAtEnd) BOOL atEnd;

@end

@implementation CSVScanner

+ (instancetype)scannerWithString:(NSString *)string
{
    CSVScanner *scanner = [[CSVScanner alloc] init];
    scanner.string = string;
    scanner.stringLength = string.length;
    return scanner;
}

- (BOOL)isAtEnd
{
    return _scanLocation == _stringLength;
}

@end


@interface CSVReader () {
    CSVScanner *dataScanner;
    NSString *dataString;
    const char *CDataString;
	NSMutableCharacterSet *newlineCharacterSet;
	NSMutableCharacterSet *quoteEndedCharacterSet;
    NSMutableCharacterSet *quoteAndEscapeSet;
    BOOL unquoted;
	NSRegularExpression *numberRegex;
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

-(instancetype)initWithString:(NSString *)newDataString configuration:(CSVConfiguration *)config{
    self = [super init];
    if(self) {
        dataString = newDataString;
        [self initVariables:config];
    }
    return self;
}

-(void)initVariables:(CSVConfiguration *)config{
    _config = config.copy;
    if([_config.quoteCharacter isEqualToString:@""]) unquoted = YES;
    _atEnd = NO;
}


-(BOOL)initScannerWithError:(NSError **)outError skipQuotes:(BOOL)skip{
    if(!dataScanner){
        if(skip){
            _config.columnSeparator = @"\t";
            _config.quoteCharacter = @"";
            _config.decimalMark = [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator];
        }
        
        if(!dataString){
            dataString = [[NSString alloc] initWithData:_data encoding:_config.encoding];
        }
        CDataString = [dataString cStringUsingEncoding:_config.encoding];
        if(!dataString) {
            if(outError != NULL) {
                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:1 userInfo: @{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"Try specifying a different encoding."}];
            }
            return NO;
        }
        dataScanner = [CSVScanner scannerWithString:dataString];

		newlineCharacterSet = [NSCharacterSet newlineCharacterSet].mutableCopy;
		[newlineCharacterSet removeCharactersInString:@"\x0b\x0c"];
        quoteEndedCharacterSet = newlineCharacterSet.mutableCopy;
        [quoteEndedCharacterSet addCharactersInString:_config.columnSeparator];
        quoteAndEscapeSet = [[NSMutableCharacterSet alloc]init];
        [quoteAndEscapeSet addCharactersInString:_config.quoteCharacter];
        [quoteAndEscapeSet addCharactersInString:_config.escapeCharacter];
        
        numberRegex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"^\\s*[+-]?(\\d+\\%@?\\d*|\\d*\\%@?\\d+)([eE][+-]?\\d+)?\\s*$",_config.decimalMark,_config.decimalMark] options:0 error:NULL];
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
    
    while(!_atEnd){
        NSString *scannedString = nil;
        NSError *scanError = nil;
        
        BOOL didScan = NO;
        if(!unquoted){
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
        
        if(scannedString.length > 0 && [numberRegex numberOfMatchesInString:scannedString options:0 range:NSMakeRange(0, [scannedString length])] == 1){
            [rowArray addObject:[NSDecimalNumber decimalNumberWithString:scannedString locale:@{NSLocaleDecimalSeparator:_config.decimalMark}]];
        }else{
            [rowArray addObject:scannedString];
        }
        
        if(dataScanner.isAtEnd){
            _atEnd = YES;
            break;
        }
        
        if([newlineCharacterSet characterIsMember:CDataString[dataScanner.scanLocation]]){
            dataScanner.scanLocation++;
			if(dataScanner.isAtEnd) _atEnd = YES;
            break;
        }
        
        //scanning column separator
        dataScanner.scanLocation++;
    }
    
    if (_atEnd && !rowArray.count) {
        return nil;
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
        if([numberRegex numberOfMatchesInString:scannedString options:0 range:NSMakeRange(0, [scannedString length])] == 1){
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
        
        if(dataScanner.isAtEnd){
            _atEnd = YES;
            break;
        }
        
        if([newlineCharacterSet characterIsMember:CDataString[dataScanner.scanLocation]]){
            dataScanner.scanLocation++;
            break;
        }
        
        //scanning column separator
        dataScanner.scanLocation++;
    }
    
    return rowArray;
}

-(BOOL)scanQuotedValueIntoString:(NSString **)scannedString error:(NSError**)outError {
    
    if(dataScanner.isAtEnd) {
        *scannedString = @"";
        return YES;
    }
    
    if(CDataString[dataScanner.scanLocation] != '\"'){
        return NO;
    }

    dataScanner.scanLocation++;
    NSRange stringRange = NSMakeRange(dataScanner.scanLocation, 0);

    while(!dataScanner.isAtEnd){
        while(!dataScanner.isAtEnd && ![quoteAndEscapeSet characterIsMember:CDataString[dataScanner.scanLocation]]){
            stringRange.length++;
            dataScanner.scanLocation++;
        }
        
        if(dataScanner.isAtEnd){
            if(outError != NULL) {
                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"Try specifying a different separator or quote."}];
            }
            return NO;
        }
        
        if(CDataString[dataScanner.scanLocation] == [_config.escapeCharacter characterAtIndex:0]) {
            if([_config.escapeCharacter isEqualToString:_config.quoteCharacter]){
                if((dataScanner.scanLocation+2 <= dataString.length && [quoteEndedCharacterSet characterIsMember:CDataString[dataScanner.scanLocation + 1]]) || dataScanner.scanLocation+1 == dataString.length){
                    dataScanner.scanLocation++;
                    *scannedString = [dataScanner.string substringWithRange:stringRange];
                    [self checkForCRLF];
                    return YES;
                }
            }
            
            dataScanner.scanLocation++;
            if(dataScanner.isAtEnd){
                if(outError != NULL) {
                    *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"Try specifying a different separator or quote."}];
                }
                return NO;
            }
            stringRange.length++;
            dataScanner.scanLocation++;
            continue;
        }
        
        if(CDataString[dataScanner.scanLocation] == [_config.quoteCharacter characterAtIndex:0]) {
            dataScanner.scanLocation++;
            if(dataScanner.isAtEnd || [quoteEndedCharacterSet characterIsMember:CDataString[dataScanner.scanLocation]]){
                *scannedString = [dataScanner.string substringWithRange:stringRange];
                [self checkForCRLF];
                return YES;
            }
            if(outError != NULL) {
                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"Try specifying a different separator or quote."}];
            }
            return NO;
        }
        
    }
    if(outError != NULL) {
        *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"Try specifying a different separator or quote."}];
    }
    return NO;
}

-(BOOL)scanUnquotedValueIntoString:(NSString **)scannedString error:(NSError **)outError{
    
    NSRange stringRange = NSMakeRange(dataScanner.scanLocation, 0);
    while(!dataScanner.isAtEnd && ![quoteEndedCharacterSet characterIsMember:CDataString[dataScanner.scanLocation]]){
        if(CDataString[dataScanner.scanLocation] == '\"' && !unquoted){
            if(outError != NULL) {
                *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Could not read data", NSLocalizedRecoverySuggestionErrorKey:@"Try specifying a different separator or quote."}];
            }
            return NO;
        }
        stringRange.length++;
        dataScanner.scanLocation++;
    }
    *scannedString = [dataScanner.string substringWithRange:stringRange];
    [self checkForCRLF];
    return YES;
}

-(void)reset{
    dataScanner = nil;
}

-(void)checkForCRLF{
    if(dataScanner.scanLocation + 2 > dataString.length) return;
    if(CDataString[dataScanner.scanLocation] == '\r' && CDataString[dataScanner.scanLocation + 1] == '\n'){
        dataScanner.scanLocation++;
    }
}

@end

