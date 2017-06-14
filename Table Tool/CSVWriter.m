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
    NSString *errorCode4;
}


-(instancetype)initWithDataArray:(NSArray *)dataArray columnsOrder:(NSArray *)columnsOrder configuration:(CSVConfiguration *)config{
    self = [super init];
    if(self) {
        _dataArray = dataArray;
        _config = config.copy;
        _columnsOrder = columnsOrder;
        errorCode4 = @"Try to specifiy another encoding to export data";
    }
    return self;
}

-(NSString *)writeString {
    
    NSMutableString *dataString = [[NSMutableString alloc]init];
    
    for(NSMutableArray *lineArray in _dataArray) {
        
        for(NSString *columndIdentifier in _columnsOrder) {
            
            for(NSUInteger i = lineArray.count; i <= columndIdentifier.integerValue;i++){
                [lineArray addObject:@""];
            }
            
            NSString *cellString;
            if([lineArray[columndIdentifier.integerValue] isKindOfClass:[NSDecimalNumber class]]){
                cellString = [lineArray[columndIdentifier.integerValue] descriptionWithLocale:@{NSLocaleDecimalSeparator:_config.decimalMark}];
            }else{
                cellString = lineArray[columndIdentifier.integerValue];
            }
            NSMutableString *temporaryCellValue = [[NSMutableString alloc]init];

            if([_config.quoteCharacter isEqualToString:@"\""]) {
                [temporaryCellValue appendString:cellString];
                if(![_config.escapeCharacter isEqualToString:_config.quoteCharacter]){
                    [temporaryCellValue replaceOccurrencesOfString:_config.escapeCharacter withString:[NSString stringWithFormat:@"%@%@",_config.escapeCharacter,_config.escapeCharacter] options:0 range:NSMakeRange(0, temporaryCellValue.length)];
                }
                [temporaryCellValue replaceOccurrencesOfString:_config.quoteCharacter withString:[NSString stringWithFormat:@"%@%@",_config.escapeCharacter,_config.quoteCharacter] options:0 range:NSMakeRange(0, temporaryCellValue.length)];
                [temporaryCellValue insertString:[NSString stringWithFormat:@"%@",_config.quoteCharacter] atIndex:0];
                [temporaryCellValue appendString:_config.quoteCharacter];
                [dataString appendString:temporaryCellValue];
                
            } else {
                [dataString appendString:cellString];
            }
            [dataString appendString:_config.columnSeparator];
        }
        [dataString deleteCharactersInRange:NSMakeRange([dataString length] -1,1)];
        [dataString appendString:@"\n"];
    }
    
    if(dataString.length != 0){
        [dataString deleteCharactersInRange:NSMakeRange([dataString length] -1,1)];
    }else{
        [dataString appendString:@""];
    }
    
    return dataString;
}

-(NSData *)writeDataWithError:(NSError *__autoreleasing *)outError {
    NSString *dataString = [self writeString];
    
    NSData *finalData = [dataString dataUsingEncoding:_config.encoding];
    if(finalData == nil){
        if(outError != NULL) {
            *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:4 userInfo:@{NSLocalizedDescriptionKey: @"Could not write data", NSLocalizedRecoverySuggestionErrorKey:errorCode4}];
        }
        return nil;
    }
    
    return finalData;
}

@end
