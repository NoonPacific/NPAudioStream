// NPAudioStream.h
//
// Copyright (c) 2015 Noon Pacific (http://noonpacific.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <AVFoundation/AVFoundation.h>


extern NSString * const NPAudioStreamStatusDidChangeNotification;
extern NSString * const NPAudioStreamRepeatModeDidChangeNotification;
extern NSString * const NPAudioStreamShuffleModeDidChangeNotification;
extern NSString * const NPAudioStreamCurrentTimeDidChangeNotification;
extern NSString * const NPAudioStreamLoadedTimeRangeDidChangeNotification;


@class NPAudioStream;

/**
 `NPAudioStream` primarily augments Apple's `AVAudioQueuePlayer` class to better interface with a networked audio playlist with iPod-style controls.
 ##Usage Notes
 Ideally an instance of NPAudioStream is kept as a singular instance within your application (perhaps within a singleton container) to prevent malfunctioning.
 */

typedef NS_ENUM(NSInteger, NPAudioStreamStatus) {
    NPAudioStreamStatusUnknown = 0,
    NPAudioStreamStatusBuffering = 1,
    NPAudioStreamStatusPaused = 2,
    NPAudioStreamStatusPlaying = 3
};

typedef NS_ENUM(NSInteger, NPAudioStreamRepeatMode) {
    NPAudioStreamRepeatModeOff = 0,
    NPAudioStreamRepeatModeAll = 1,
    NPAudioStreamRepeatModeOne = 2
};

typedef NS_ENUM(NSInteger, NPAudioStreamShuffleMode) {
    NPAudioStreamShuffleModeOff = 0,
    NPAudioStreamShuffleModeOn = 1
};

///---------------
/// @name Delegate
///---------------

@protocol NPAudioStreamDelegate <NSObject>

@optional

- (void)audioStream:(NPAudioStream *)audioStream didUpdateStatus:(NPAudioStreamStatus)status;
- (void)audioStream:(NPAudioStream *)audioStream didUpdateRepeatMode:(NPAudioStreamRepeatMode)repeatMode;
- (void)audioStream:(NPAudioStream *)audioStream didUpdateShuffleMode:(NPAudioStreamShuffleMode)shuffleMode;

- (void)didCompleteAudioStream:(NPAudioStream *)audioStream;
- (void)didRequestPreviousStreamForAudioStream:(NPAudioStream *)audioStream;

- (void)audioStream:(NPAudioStream *)audioStream didLoadTrackAtIndex:(NSInteger)index;
- (void)audioStream:(NPAudioStream *)audioStream didBeginPlaybackForTrackAtIndex:(NSInteger)index;

- (void)audioStream:(NPAudioStream *)audioStream didUpdateTrackCurrentTime:(CMTime)currentTime;
- (void)audioStream:(NPAudioStream *)audioStream didUpdateTrackLoadedTimeRange:(CMTimeRange)loadedTimeRange;
- (void)audioStream:(NPAudioStream *)audioStream didFinishSeekingToTime:(CMTime)time;

@end


@protocol NPAudioStreamDataSource <NSObject>

@optional

- (BOOL)shouldPrebufferNextTrackForAudioStream:(NPAudioStream *)audioStream;

@end

/**
 An instance of NPAudioStream is a means for playing and controlling an array of remote audio sources.
 */
@interface NPAudioStream : NSObject {
    __weak id <NPAudioStreamDelegate> delegate;
    __weak id <NPAudioStreamDataSource> dataSource;
}

///-------------------------
/// @name Stream Controllers
///-------------------------

/**
 The object that acts as the delegate of the audio stream.
 
 The delegate must adopt the NPAudioStreamDelegate protocol. The delegate is not retained.
 */
@property (nonatomic, weak) id <NPAudioStreamDelegate> delegate;

/**
 The object that acts as the delegate of the audio stream.
 
 The delegate must adopt the NPAudioStreamDelegate protocol. The delegate is not retained.
 */
@property (nonatomic, weak) id <NPAudioStreamDataSource> dataSource;

/**
 Returns the status of the audio stream. (read-only)
 */
@property (nonatomic, assign, readonly) NPAudioStreamStatus status;

/**
 The repeat mode for the audio stream.
 */
@property (nonatomic, assign) NPAudioStreamRepeatMode repeatMode;

/**
 The shuffle mode for the audio stream.
 */
@property (nonatomic, assign) NPAudioStreamShuffleMode shuffleMode;


/**
 An array of NSURL objects pointing towards audio sources.
 
 @warning Must only contain NSURL objects (enforced).
 */
@property (nonatomic, strong) NSArray *urls;

/**
 Select an item within the `urls` array for playback.
 
 @param index The index of the item in the `urls` array to use for playback.
 */
- (void)selectIndexForPlayback:(NSInteger)index;

/**
 Cycle to the next repeat mode.
 */
- (void)incrementRepeatMode;

/**
 Cycle to the next shuffle mode.
 */
- (void)incrementShuffleMode;


///---------------------------------------
/// @name Current Audio Source Controllers
///---------------------------------------

/**
 The current time of the current audio source. (read-only)
 */
@property (nonatomic, readonly) CMTime currentTime;

/**
 The duration of the current audio source. (read-only)
 */
@property (nonatomic, readonly) CMTime duration;

/**
 The time range for which the current audio source has the media data readily available. The range provided might be discontinous. (read-only)
 */
@property (nonatomic, readonly) CMTimeRange loadedTimeRange;

/**
 Seek to a specific time (in seconds) in the current audio source.
 
 @param index The index of the item in the `urls` array to use for playback.
 */
- (void)seekToTimeInSeconds:(CGFloat)seconds;

/**
 Play the current audio source.
 */
- (void)play;

/**
 Pause the current audio source.
 */
- (void)pause;

/**
 Play the current audio source if it is currently paused, and vica versa.
 */
- (void)togglePlayPause;

/**
 Play the previous audio source in the `urls` array.
 
 Behavior will vary based on the 'repeatMode' and `shuffleMode` properties.
 */
- (void)skipPrevious;

/**
 Play the next audio source in the `urls` array.
 
 Behavior will vary based on the 'repeatMode' and `shuffleMode` properties.
 */
- (void)skipNext;

@end
