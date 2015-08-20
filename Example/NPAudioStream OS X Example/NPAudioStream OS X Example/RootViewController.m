//
//  RootViewController.m
//  NPAudioStream OS X Example
//
//  Created by Alexander Givens on 8/20/15.
//  Copyright (c) 2015 Noon Pacific. All rights reserved.
//

#import "RootViewController.h"
#import "NPAudioStream.h"

@interface RootViewController () <NPAudioStreamDelegate>

@end

@implementation RootViewController {
    NSString *soundcloudToken;
    NSArray *tracks;
    NPAudioStream *audioStream;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *keyDict = [self JSONObjectWithFileName:@"keys"];
    soundcloudToken = [keyDict objectForKey:@"soundcloud_token"];
    
    NSAssert(soundcloudToken.length != 0, @"A valid SoundCloud token is required to stream this playlist. First, generate a valid SoundCloud token from the SoundCloud developer site. Then add the token to the keys.json file in the project root.");

    tracks = [self JSONObjectWithFileName:@"mixtape-151"];
    
    audioStream = [NPAudioStream new];
    [audioStream setDelegate:self];
    
    NSMutableArray *tempURLs = [NSMutableArray arrayWithCapacity:tracks.count];
    
    for (NSDictionary *track in tracks) {
        
        NSString *streamURLstring = [NSString stringWithFormat:@"%@?client_id=%@", [track objectForKey:@"soundcloud_stream_url"], soundcloudToken];
        NSURL *streamURL = [NSURL URLWithString:streamURLstring];
        [tempURLs addObject:streamURL];
    }
    
    [audioStream setUrls:[NSArray arrayWithArray:tempURLs]];
}

- (void)viewDidAppear {
    [audioStream selectIndexForPlayback:0];
}


#pragma mark - Utility

- (id)JSONObjectWithFileName:(NSString *)fileName {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError* error = nil;
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
}

@end
