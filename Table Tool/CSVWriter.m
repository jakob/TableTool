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


-(instancetype)initWithDataArray:(NSArray *)dataArray {
    self = [super init];
    if(self) {
        _dataArray = dataArray;
        _quoteCharacter = @"\"";
        _columnSeparator = @",";
        _encoding = NSUTF8StringEncoding;
        _escapeCharacter = @"\\";
        quoteOrColumnSeparator = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@"%@%@",_quoteCharacter,_columnSeparator]];
    }
    return self;
}

-(NSData *)writeData:(NSError *__autoreleasing *)outError {
    
    NSMutableString *dataString = [[NSMutableString alloc]init];
    
    for(NSArray *lineArray in _dataArray) {
        for(NSString *cellString in lineArray) {
            BOOL shouldSetQuotes = [cellString rangeOfCharacterFromSet:quoteOrColumnSeparator].location == NSNotFound ? NO : YES;
            if(shouldSetQuotes) {
                [dataString appendString:_quoteCharacter];
            }
            [dataString appendString:cellString];
            if(shouldSetQuotes) {
                [dataString appendString:_quoteCharacter];
            }
            [dataString appendString:_columnSeparator];
        }
        [dataString deleteCharactersInRange:NSMakeRange([dataString length] -1,1)];
        [dataString appendString:@"\n"];
    }
    [dataString deleteCharactersInRange:NSMakeRange([dataString length] -1,1)];
    NSData *finalData = [dataString dataUsingEncoding:_encoding];
    
    return finalData;
}

@end
