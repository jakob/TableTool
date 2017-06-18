//
//  NSFileHandle+TempFile.m
//  Table Tool
//
//  Created by Martin Köhler on 18.06.17.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

#import "NSFileHandle+TempFile.h"

@implementation NSFileHandle (TempFile)

+ (NSFileHandle * _Nullable)tempFileForTestClass:(NSString * _Nonnull)className
                                        selector:(NSString * _Nonnull)selector
                        fileNameWithoutExtension:(NSString * _Nonnull)fileName
                                       extension:(NSString * _Nonnull)extension
                                         getPath:(NSMutableString * _Nonnull)outPath
                                           error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    NSString *containerDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",className,selector,nil]];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:containerDir withIntermediateDirectories:YES attributes:nil error:error];
    
    NSString *fileNameTemplate = [NSString stringWithFormat:@"%@.XXXX.%@",fileName,extension,nil];
    
    NSString *path = [containerDir stringByAppendingPathComponent:fileNameTemplate];
    
    const char *templateCString = [path fileSystemRepresentation];

    char *tempFileCString = (char *)malloc(strlen(templateCString) + 1);
    strcpy(tempFileCString, templateCString);
    
    int fileDescriptor = mkstemps(tempFileCString, (int)([extension length] + 1));

    if (fileDescriptor == -1) {
        free(tempFileCString);
        
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        return nil;
    }
    
    NSString *tempPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileCString
                                                                                     length:strlen(tempFileCString)];
    
    free(tempFileCString);

    
    [outPath setString:tempPath];
    
    return [[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor closeOnDealloc:YES];
}

@end
