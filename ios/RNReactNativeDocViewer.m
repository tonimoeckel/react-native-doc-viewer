//
//  RNReactNativeDocViewer.m
//  RNReactNativeDocViewer
//
//  Created by Philipp Hecht on 10/03/17.
//  Copyright (c) 2017 Philipp Hecht. All rights reserved.
//
#import "RNReactNativeDocViewer.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "RCTRootView.h"
#if __has_include("RCTLog.h")
#import "RCTLog.h"
#else
#import <React/RCTLog.h>
#endif


@implementation RNReactNativeDocViewer


RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(testModule:(NSString *)name location:(NSString *)location)
{
    RCTLogInfo(@"TEST Module %@ at %@", name, location);
}

/**
 * openDoc
 * open Base64 String
 * Parameters: NSArray
 */
RCT_EXPORT_METHOD(openDoc:(NSArray *)array callback:(RCTResponseSenderBlock)callback)
{
    
    NSDictionary* dict = [array objectAtIndex:0];
    NSString* urlStr = dict[@"url"];
    NSString* fileName = dict[@"fileName"];
    NSURL* url = [NSURL URLWithString:urlStr];
    
    
    if ([urlStr hasPrefix:@"http://"] || [urlStr hasPrefix:@"https://"]){
        RCTLogInfo(@"URL %@", urlStr);
        
        NSString* urlFileName = [url lastPathComponent];
        NSString* filePath = [NSTemporaryDirectory() stringByAppendingPathComponent: urlFileName];
        
        
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (error) {
                NSLog(@"Download Error:%@",error.description);
            }
            if (data) {
                
                NSURL* tmpFileUrl = [[NSURL alloc] initFileURLWithPath:filePath];
                RCTLogInfo(@"Open Local File %@", tmpFileUrl.absoluteString);
                [data writeToURL:tmpFileUrl atomically:YES];
                self.fileUrl = tmpFileUrl;
                [self openQuicklookViewController];
                if (callback) {
                    callback(@[[NSNull null], array]);
                }
            }
        }];
    }else {
        
        NSURL* tmpFileUrl = [[NSURL alloc] initFileURLWithPath:urlStr];
        RCTLogInfo(@"Open Local File %@", tmpFileUrl.absoluteString);
        self.fileUrl = tmpFileUrl;
        [self openQuicklookViewController];
        if (callback) {
            callback(@[[NSNull null], array]);
        }
    }
    
  
}
/**
 * openDocb64
 * open Base64 String
 * Parameters: NSArray
 */
RCT_EXPORT_METHOD(openDocb64:(NSArray *)array callback:(RCTResponseSenderBlock)callback)
{
    
    __weak RNReactNativeDocViewer* weakSelf = self;
    dispatch_queue_t asyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(asyncQueue, ^{
        NSDictionary* dict = [array objectAtIndex:0];
        NSString* base64String = dict[@"base64"];
        NSString* filename = dict[@"fileName"];
        NSString* filetype = dict[@"fileType"];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"data:application/octet-stream;base64,%@",base64String]];
        NSData* dat = [NSData dataWithContentsOfURL:url];
        if (dat == nil) {
            if (callback) {
                callback(@[[NSNull null], @"DATA nil"]);
            }
            return;
        }
        NSString* fileName = [NSString stringWithFormat:@"%@%@%@", filename, @".", filetype];
        NSString* fileExt = [fileName pathExtension];
        if([fileExt length] == 0){
            fileName = [NSString stringWithFormat:@"%@%@", fileName, @".pdf"];
        }
        NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent: fileName];
        NSURL* tmpFileUrl = [[NSURL alloc] initFileURLWithPath:path];
        
        [dat writeToURL:tmpFileUrl atomically:YES];
        weakSelf.fileUrl = tmpFileUrl;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            QLPreviewController* cntr = [[QLPreviewController alloc] init];
            cntr.delegate = weakSelf;
            cntr.dataSource = weakSelf;
            if (callback) {
                callback(@[[NSNull null], @"Data"]);
            }
            UIViewController* root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
            [root presentViewController:cntr animated:YES completion:nil];
        });
        
    });
}

//Movie Files mp4
RCT_EXPORT_METHOD(playMovie:(NSString *)file callback:(RCTResponseSenderBlock)callback)
{
    //NSDictionary* dict = [array objectAtIndex:0];
    NSString *_uri = file;
    
    NSString* mediaFilePath = [[NSBundle mainBundle] pathForResource:_uri ofType:nil];
    NSAssert(mediaFilePath, @"Media not found: %@", _uri);
    
    NSURL *fileURL = [NSURL fileURLWithPath:mediaFilePath];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        AVPlayerViewController *movieViewController = [[AVPlayerViewController alloc] init];
        
        movieViewController.player = [AVPlayer playerWithURL:fileURL];
        
        [movieViewController.player play];
        
        movieViewController = movieViewController;
        
        UIViewController *ctrl = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        UIView *view = [ctrl view];
        
        view.window.windowLevel = UIWindowLevelStatusBar;
        if (callback) {
            callback(@[[NSNull null], @"true"]);
        }
        
        [ctrl presentViewController:movieViewController animated:TRUE completion: nil];
        
    });
}

- (NSInteger) numberOfPreviewItemsInPreviewController: (QLPreviewController *) controller
{
    return 1;
}

- (id <QLPreviewItem>) previewController: (QLPreviewController *) controller previewItemAtIndex: (NSInteger) index
{
    return [NSURL URLWithString:[self.fileUrl absoluteString]];
}


#pragma mark - QLPreviewItem protocol
//
//- (NSURL*)previewItemURL
//{
//    return self.fileUrl;
//}
//


-(void) openQuicklookViewController {
    
    
    QLPreviewController* previewController = [[QLPreviewController alloc] init];
    previewController.dataSource = self;
    
    NSLog(@"%@",[UIApplication sharedApplication].delegate.window.rootViewController);
    
    [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:previewController animated:YES completion: nil];
    
}

@end

