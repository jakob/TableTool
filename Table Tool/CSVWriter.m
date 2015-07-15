//
//  CSVWriter.m
//  Table Tool
//
//  Created by Andreas Aigner on 10.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import "CSVWriter.h"

@implementation CSVWriter {
    NSCharacterSet *quoteOrColumnSeparator;
}


-(instancetype)initWithDataArray:(NSArray *)dataArray andColumnsOrder:(NSArray *)columnsOrder{
    self = [super init];
    if(self) {
        _dataArray = dataArray;
        _quoteCharacter = @"\"";
        _columnSeparator = @",";
        _encoding = NSUTF8StringEncoding;
        _escapeCharacter = @"\\";
        _columnsOrder = columnsOrder;
    }
    return self;
}

-(NSData *)writeDataWithError:(NSError *__autoreleasing *)outError {
    
    NSMutableString *dataString = [[NSMutableString alloc]init];
    
    for(NSMutableArray *lineArray in _dataArray) {
        
        for(NSString *columndIdentifier in _columnsOrder) {
            
            for(NSUInteger i = lineArray.count; i <= columndIdentifier.integerValue;i++){
                [lineArray addObject:@""];
            }
            NSString *cellString = lineArray[columndIdentifier.integerValue];
            NSMutableString *temporaryCellValue = [[NSMutableString alloc]init];
            BOOL shouldSetQuotes = [cellString rangeOfString:_columnSeparator ].location == NSNotFound ? NO : YES;
            shouldSetQuotes |= [cellString rangeOfString:_quoteCharacter ].location == NSNotFound ? NO : YES;
            if(![_escapeCharacter isEqualToString:_quoteCharacter]){
                shouldSetQuotes |= [cellString rangeOfString:@"\\"].location == NSNotFound ? NO : YES;
            }
            
            if(shouldSetQuotes) {
                [temporaryCellValue appendString:cellString];
                if(![_escapeCharacter isEqualToString:_quoteCharacter]){
                    [temporaryCellValue replaceOccurrencesOfString:@"\\" withString:[NSString stringWithFormat:@"%@%@",_escapeCharacter,@"\\"] options:0 range:NSMakeRange(0, temporaryCellValue.length)];
                }
                [temporaryCellValue replaceOccurrencesOfString:_quoteCharacter withString:[NSString stringWithFormat:@"%@%@",_escapeCharacter,_quoteCharacter] options:0 range:NSMakeRange(0, temporaryCellValue.length)];
                [temporaryCellValue insertString:@"\"" atIndex:0];
                [temporaryCellValue appendString:_quoteCharacter];
                [dataString appendString:temporaryCellValue];
                
            } else {
                [dataString appendString:cellString];
            }
            [dataString appendString:_columnSeparator];
        }
        [dataString deleteCharactersInRange:NSMakeRange([dataString length] -1,1)];
        [dataString appendString:@"\n"];
    }
    [dataString deleteCharactersInRange:NSMakeRange([dataString length] -1,1)];
    
    //TODO: Error-handling
    NSData *finalData = [dataString dataUsingEncoding:_encoding];
    if(finalData == nil){
        if(outError != NULL) {
            *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:4 userInfo:@{NSLocalizedDescriptionKey: @"Could not write data", NSLocalizedRecoverySuggestionErrorKey:@"Try to specifiy another encoding to export data"}];
        }
        return nil;
    }
    
    return finalData;
}

@end
