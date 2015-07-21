//
//  CSVConfiguration.m
//  Table Tool
//
//  Created by Andreas Aigner on 21.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import "CSVConfiguration.h"

@implementation CSVConfiguration

-(instancetype)init {
    self = [super init];
    if(self){
        _encoding = NSUTF8StringEncoding;
        _columnSeparator = @",";
        _quoteCharacter = @"\"";
        _escapeCharacter = @"\\";
        _decimalMark = @".";
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone {
    CSVConfiguration *copy = [[CSVConfiguration allocWithZone:zone]init];
    copy->_encoding = _encoding;
    copy->_columnSeparator = _columnSeparator;
    copy->_decimalMark = _decimalMark;
    copy->_escapeCharacter = _escapeCharacter;
    copy->_quoteCharacter = _quoteCharacter;
    return copy;
}

@end
