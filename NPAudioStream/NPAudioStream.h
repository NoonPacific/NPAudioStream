//
//  NPAudioStream.h
//  Noon Pacific
//
//  Created by Alex Givens on 9/22/14.
//  Copyright (c) 2014-2015 Noon Pacific. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "NPQueuePlayer.h"
#import "NPPlayerItem.h"

typedef NS_ENUM(NSUInteger, NPAudioStreamStatus) {
    NPAudioStreamStatusUnknown = 0,
    NPAudioStreamStatusBuffering = 1,
    NPAudioStreamStatusPaused = 2,
    NPAudioStreamStatusPlaying = 3
};

typedef NS_ENUM(NSUInteger, NPAudioStreamRepeatMode) {
    NPAudioStreamRepeatModeOff = 0,
    NPAudioStreamRepeatModeMix = 1,
    NPAudioStreamRepeatModeTrack = 2
};

typedef NS_ENUM(NSUInteger, NPAudioStreamShuffleMode) {
    NPAudioStreamShuffleModeOff = 0,
    NPAudioStreamShuffleModeOn = 1
};

@class NPAudioStream;

@protocol NPAudioStreamDelegate <NSObject>
@optional

- (void)audioStream:(NPAudioStream *)audioStream didUpdateStatus:(NPAudioStreamStatus)status;
- (void)audioStream:(NPAudioStream *)audioStream didUpdateRepeatMode:(NPAudioStreamRepeatMode)repeatMode;
- (void)audioStream:(NPAudioStream *)audioStream didUpdateShuffleMode:(NPAudioStreamShuffleMode)shuffleMode;

- (void)didCompleteAudioStream:(NPAudioStream *)audioStream;
- (void)didRequestPreviousStreamForAudioStream:(NPAudioStream *)audioStream;

- (void)audioStream:(NPAudioStream *)audioStream didLoadTrackAtIndex:(NSUInteger)index;
- (void)audioStream:(NPAudioStream *)audioStream didBeginPlaybackForTrackAtIndex:(NSUInteger)index;

- (void)audioStream:(NPAudioStream *)audioStream didUpdateTrackCurrentTime:(CMTime)currentTime;
- (void)audioStream:(NPAudioStream *)audioStream didUpdateTrackLoadedTimeRange:(CMTimeRange)loadedTimeRange;
- (void)audioStream:(NPAudioStream *)audioStream didFinishSeekingToTime:(CMTime)time;

- (BOOL)shouldPrebufferNextTrackForAudioStream:(NPAudioStream *)audioStream;

@end

@interface NPAudioStream : NSObject {
    __weak id <NPAudioStreamDelegate> delegate;
}

@property (nonatomic, weak) id <NPAudioStreamDelegate> delegate;
@property (nonatomic, assign, readonly) NPAudioStreamStatus status;
@property (nonatomic, assign) NPAudioStreamRepeatMode repeatMode;
@property (nonatomic, assign) NPAudioStreamShuffleMode shuffleMode;
@property (nonatomic, strong) NPQueuePlayer *player;
@property (nonatomic, strong) NSArray *urls;
@property (nonatomic, readonly) CMTime currentTime;
@property (nonatomic, readonly) CMTime duration;
@property (nonatomic, readonly) CMTimeRange loadedTimeRange;

- (void)selectIndexForPlayback:(NSUInteger)index;
- (void)seekToTimeInSeconds:(CGFloat)seconds;
- (void)play;
- (void)pause;
- (void)skipPrevious;
- (void)skipNext;

@end
