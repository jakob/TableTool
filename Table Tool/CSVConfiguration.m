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
        _escapeCharacter = @"\"";
        _decimalMark = @".";
        _firstRowAsHeader = NO;
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
    copy->_firstRowAsHeader = _firstRowAsHeader;
    return copy;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"separator: \'%@\', quote: \'%@\', escape: \'%@\', decimal: \'%@\', firstAsHeader: %@",
            _columnSeparator, _quoteCharacter, _escapeCharacter, _decimalMark, _firstRowAsHeader ? @"YES" : @"NO"];
}

+(NSArray<NSArray*>*)supportedEncodings {
	return @[
	  @[@"Unicode (UTF-8)", @(0x4)],
	  @[@"Western (Mac OS Roman)", @(0x1e)],
	  @[@"Western (Windows Latin 1)", @(0xc)],
	  @[@"Chinese (GBK)", @(0x80000632)],
	  @[@"Central European (ISO Latin 2)", @(0x9)],
	  @[@"Central European (Windows Latin 2)", @(0xf)],
	  @[@"Cyrillic (Windows)", @(0xb)],
	  @[@"Greek (Windows)", @(0xd)],
	  @[@"Turkish (Windows)", @(0xe)],
	  @[@"Japanese (EUC)", @(0x3)],
	  @[@"Japanese (Shift_JIS)", @(0x8)],
	  @[@"Japanese (ISO 2022-JP)", @(0x15)],
	  @[@"Unicode (UTF-16)", @(0xa)],
	  @[@"Unicode (UTF-16, Big Endian)", @(0x90000100)],
	  @[@"Unicode (UTF-16, Little Endian)", @(0x94000100)],
	  @[@"Unicode (UTF-32)", @(0x8c000100)],
	  @[@"Unicode (UTF-32, Big Endian)", @(0x98000100)],
	  @[@"Unicode (UTF-32, Little Endian)", @(0x9c000100)],
    ];
}

@end
