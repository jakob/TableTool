//
//  OpenFromUrlWindowController.m
//  Table Tool
//
//  Created by GuZhangYiDong on 2016/12/19.
//  Copyright © 2016年 Egger Apps. All rights reserved.
//

#import "OpenFromUrlWindowController.h"
#import "AFNetworking.h"

@interface OpenFromUrlWindowController ()

@end

@implementation OpenFromUrlWindowController

- (void)windowDidLoad {
  [super windowDidLoad];
}

- (IBAction)openFromUrl:(NSButton *)sender {
//  NSString *URLString = @"http://tsdb.stockpalm.com/v1/tsdb/q";
//  NSDictionary *parameters = @{@"db": @"stock", @"series": @"002815", @"csv": @"true"};
  
  NSError *fileError = nil;
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *docdir = [paths firstObject];
  NSString *filePath = [NSString stringWithFormat:@"%@/q",docdir];
  [[NSFileManager defaultManager] removeItemAtPath:filePath error:&fileError];
  
  NSString *URLString = self.urlInputTextField.stringValue;
  NSMutableURLRequest *req = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:URLString parameters:nil error:nil];

  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
  AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
  
  NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:req progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
  } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
    NSError *outError = nil;
    [self.doc readFromURL:filePath ofType:@"" error:&outError];
    [self close];
  }];
  [downloadTask resume];
}


@end
