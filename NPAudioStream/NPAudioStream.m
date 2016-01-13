// NPAudioStream.m
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

#import "NPAudioStream.h"
#import "NPQueuePlayer.h"
#import "NPPlayerItem.h"

#if TARGET_OS_IOS
    #import "UIKit/UIKit.h"
    #import "UIAlertView+Extensions.h"
#endif

#import "NSURL+Extensions.h"
#import "NSMutableArray+Extensions.h"


NSString * const NPAudioStreamStatusDidChangeNotification = @"com.npaudiostream.statusdidchangenotification";
NSString * const NPAudioStreamRepeatModeDidChangeNotification = @"com.npaudiostream.repeatmodedidchangenotification";
NSString * const NPAudioStreamShuffleModeDidChangeNotification = @"com.npaudiostream.shufflemodedidchangenotification";
NSString * const NPAudioStreamCurrentTimeDidChangeNotification = @"com.npaudiostream.currenttimedidchangenotification";
NSString * const NPAudioStreamLoadedTimeRangeDidChangeNotification = @"com.npaudiostream.loadedtimerangedidchangenotification";


NSInteger static requiredBufferToResume = 4;

/* AVAsset Keys */
NSString *kTracksKey            = @"tracks";
NSString *kPlayableKey          = @"playable";
NSString *kDurationKey          = @"duration";

@interface NPAudioStream () <NPQueuePlayerDelegate, NPPlayerItemDelegate>

@property (nonatomic) NSURL *currentURL;
@property (nonatomic, strong) NSArray *shuffledURLs;
@property (nonatomic, strong, readonly) NSArray *conditionalURLs;
@property (nonatomic, strong) NPQueuePlayer *player;

@end

@implementation NPAudioStream {
    
    NSMutableArray *assets;

    id periodicTimeObserver;
    id beginningBoundaryTimeObserver;
    
    BOOL wasPlayingWhenInterruptionBegan;
    BOOL bufferingToResumePlayback;
    NSTimeInterval bufferedSecondsWhenPlaybackStopped;
    
#if TARGET_OS_IOS
    UIBackgroundTaskIdentifier bgTaskID;
#endif
}

@synthesize delegate, dataSource;

- (id)init {
    self = [super init];
    if (self) {
        
        _status = NPAudioStreamStatusUnknown;
        _repeatMode = NPAudioStreamRepeatModeOff;
        _shuffleMode = NPAudioStreamShuffleModeOff;
        assets = [NSMutableArray new];
        
        #if TARGET_OS_IOS
        [self subscribeToInterruptionNotification];
        #endif
        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Audio Interruption
#if TARGET_OS_IOS

- (void)subscribeToInterruptionNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];
}

- (void)interruption:(NSNotification *)notification {
    
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger interuptionType = [[interuptionDict valueForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    
    switch (interuptionType) {
            
        case AVAudioSessionInterruptionTypeBegan:
            
            wasPlayingWhenInterruptionBegan = _player.isPlaying;
            
            break;
            
        case AVAudioSessionInterruptionTypeEnded: {
            
            NSInteger interruptionOption = [[interuptionDict valueForKey:AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
            
            if (interruptionOption == AVAudioSessionInterruptionOptionShouldResume) {
                
                if (wasPlayingWhenInterruptionBegan) [self play];
                wasPlayingWhenInterruptionBegan = NO;
                
            }
            
            break;
            
        }
    }
}

#endif

#pragma mark - Specified Audio Controls

- (void)selectIndexForPlayback:(NSInteger)selectedIndex {
    
    if (_urls == nil || _urls.count == 0 || _urls.count < selectedIndex) return;
    
    NSInteger currentItemIndex = [_urls indexOfObject:_currentURL];
    
    if (selectedIndex == currentItemIndex) {
        if (!_player.isPlaying) [_player play];
        return;
    }
    
    if (_shuffleMode == NPAudioStreamShuffleModeOn) [self generateShuffleArrayWithFirstIndex:selectedIndex];
    
    NSURL *selectedURL = (NSURL *)[_urls objectAtIndex:selectedIndex];
    
    [self playURL:selectedURL];
}

#pragma mark - Relative Audio Controls

- (void)seekToTimeInSeconds:(CGFloat)seconds {
    
    float restoreAfterScrubbingRate = _player.rate;
    _player.rate = 0.0f;
    
    [self removeTimeObservers];
    
    int32_t timeScale = _player.currentItem.asset.duration.timescale;
    CMTime time = CMTimeMakeWithSeconds(seconds, timeScale);
    
    [_player seekToTime:time
      completionHandler:^(BOOL finished) {
          
          [self initTimeObservers];
          
          _player.rate = restoreAfterScrubbingRate;
          
          if ([delegate respondsToSelector:@selector(audioStream:didFinishSeekingToTime:)]) {
              [delegate audioStream:self didFinishSeekingToTime:time];
          }
          
      }];
}

#pragma mark - Audio

- (void)play {
    bufferingToResumePlayback = NO;
    [_player play];
}

- (void)pause {
    bufferingToResumePlayback = NO;
    [_player pause];
}

- (void)togglePlayPause {
    if (self.status == NPAudioStreamStatusPlaying) {
        [self pause];
    } else if (self.status == NPAudioStreamStatusPaused) {
        [self play];
    }
}

- (void)skipNext {
    
    NSInteger nextURLIndex = [self.conditionalURLs indexOfObject:_currentURL] + 1;
    
    if (nextURLIndex < self.conditionalURLs.count) {
        
        NSURL *nextURL = [self.conditionalURLs objectAtIndex:nextURLIndex];
        [self playURL:nextURL];
        
    } else {
        
        if (_repeatMode == NPAudioStreamRepeatModeAll) {
            
            [self generateShuffleArray];
            
            NSURL *firstURL = [self.conditionalURLs firstObject];
            [self playURL:firstURL];
            
        } else {
            
            if ([delegate respondsToSelector:@selector(didCompleteAudioStream:)]) {
                [delegate didCompleteAudioStream:self];
            }
        }
    }
}

- (void)skipPrevious {
    
    if (CMTIME_COMPARE_INLINE(_player.currentTime, >, CMTimeMake(5.0, 1.0))) {
        [_player.currentItem seekToTime:kCMTimeZero];
        return;
    }
    
    NSInteger previousURLIndex = [self.conditionalURLs indexOfObject:_currentURL] - 1;
    
    if (previousURLIndex < self.conditionalURLs.count) {
        
        NSURL *previousURL = [self.conditionalURLs objectAtIndex:previousURLIndex];
        [self playURL:previousURL];
        
    } else {
        
        if (_repeatMode == NPAudioStreamRepeatModeAll) {
            
            [self generateShuffleArray];
            
            NSURL *lastURL = [self.conditionalURLs lastObject];
            [self playURL:lastURL];
            
        } else {
            
            if ([delegate respondsToSelector:@selector(didRequestPreviousStreamForAudioStream:)]) {
                [delegate didRequestPreviousStreamForAudioStream:self];
            }
        }
    }
}

- (void)playURL:(NSURL *)url {
    bufferingToResumePlayback = NO;

    _currentURL = url;
    
    [_player pause];
    
    for (AVURLAsset *asset in assets) [asset cancelLoading];
    for (NPPlayerItem *playerItem in _player.items) [playerItem.asset cancelLoading];
    [assets removeAllObjects];
    
    if ([delegate respondsToSelector:@selector(audioStream:didLoadTrackAtIndex:)]) {
        [delegate audioStream:self didLoadTrackAtIndex:[_urls indexOfObject:url]];
    }

    [self setStatus:NPAudioStreamStatusBuffering];

    if (_player.items.count > 1) {
        
        NPPlayerItem *nextItem = (NPPlayerItem *)[_player.items objectAtIndex:1];
        
        if ([url isEquivalent:nextItem.url]) {
            [_player.currentItem.asset cancelLoading];
            [_player advanceToNextItem];
            [self attemptToQueueUpNextURLAfterURL:url];
            return;
        }
    }
    
    for (int idx = 0; idx < _player.items.count; idx++ ) {
        NPPlayerItem *playerItem = (NPPlayerItem *)[_player.items objectAtIndex:idx];
        [playerItem.asset cancelLoading];
    }
    
    [_player removeAllItems];
    
    [self preparePlayerItemForURL:url
                      withSuccess:^(NPPlayerItem *playerItem) {
                          
                          if (!_player) {
                              
#if TARGET_OS_IOS || TARGET_OS_TV
                              [[AVAudioSession sharedInstance] setActive:YES error:nil];
                              [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
#endif
                              _player = [[NPQueuePlayer alloc] init];
                              _player.delegate = self;
                              _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
#if TARGET_OS_IOS
                              _player.allowsExternalPlayback = NO;
#endif
                          }
                          
                          [self initTimeObservers];
                          [playerItem setDelegate:self];
                          
                          [_player replaceCurrentItemWithPlayerItem:playerItem];
                          [self attemptToQueueUpNextURLAfterURL:url];
                          
                      } failure:^(NSError *error) {
                          
#ifdef DEBUG
                          NSLog(@"Failed to load item at URL (%@) with error: %@", url, error.description);
#endif
                          if (error.code == kCFURLErrorFileDoesNotExist) [self skipNext];
                      }];
}

- (void)attemptToQueueUpNextURLAfterURL:(NSURL *)url {
    
    BOOL prebuffer = YES;
    
    if ([dataSource respondsToSelector:@selector(shouldPrebufferNextTrackForAudioStream:)]) {
        prebuffer = [dataSource shouldPrebufferNextTrackForAudioStream:self];
    }
    
    if (!prebuffer) return;
    
    NSInteger nextURLIndex = [self.conditionalURLs indexOfObject:_currentURL] + 1;
    
    if (nextURLIndex < self.conditionalURLs.count) {
        
        NSURL *nextURL = [self.conditionalURLs objectAtIndex:nextURLIndex];
        
        [self preparePlayerItemForURL:nextURL
                          withSuccess:^(NPPlayerItem *playerItem) {
                              
                              [playerItem setDelegate:self];
                              
                              if ([_player canInsertItem:playerItem afterItem:_player.currentItem]) {
                                  [_player insertItem:playerItem afterItem:_player.currentItem];
                              }
                              
                          } failure:^(NSError *error) {
                              
#ifdef DEBUG
                              NSLog(@"Failed to queue up next URL (%@) with error: %@", url, error.description);
#endif
                              
                          }];
    }
}

- (void)logError:(NSError *)error withAlert:(BOOL)alert {
    
    NSLog(@"Audio Stream Error: %@", error.localizedDescription);
#if TARGET_OS_IOS
    if (alert) [UIAlertView showOKAlertWithTitle:@"Audio Stream Error" andMessage:error.localizedDescription];
#endif
}

- (void)preparePlayerItemForURL:(NSURL *)url
                    withSuccess:(void (^)(NPPlayerItem *playerItem))success
                        failure:(void (^)(NSError *error))failure {
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    [assets addObject:asset];
    
    NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, kDurationKey, nil];
    
    [asset loadValuesAsynchronouslyForKeys:requestedKeys
                         completionHandler: ^{
                             dispatch_async( dispatch_get_main_queue(), ^{
                                 
                                 [assets removeObject:asset];
                                 
                                 for (NSString *key in requestedKeys) {
                                     
                                     NSError *error = nil;
                                     AVKeyValueStatus keyStatus = [asset statusOfValueForKey:key error:&error];
                                     
                                     if (keyStatus == AVKeyValueStatusFailed) {
                                         failure(error);
                                         return;
                                     }
                                     
                                 }
                                 
                                 if (!asset.playable) {
                                     
                                     NSString *localizedDescription = NSLocalizedString(@"Item cannot be played",
                                                                                        @"Item cannot be played description");
                                     NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.",
                                                                                          @"Item cannot be played failure reason");
                                     NSDictionary *errorDict = @{NSLocalizedDescriptionKey : localizedDescription,
                                                                 NSLocalizedFailureReasonErrorKey: localizedFailureReason};
                                     NSError *error = [NSError errorWithDomain:@"NPAudioStream" code:0 userInfo:errorDict];
                                     
                                     failure(error);
                                     return;
                                 }
                                 
                                 NPPlayerItem *playerItem = [[NPPlayerItem alloc] initWithAsset:asset];
                                 [playerItem setUrl:url];
                                 
                                 success(playerItem);
                                 
                             });
                         }];
}

- (void)incrementRepeatMode {
    if (self.repeatMode == NPAudioStreamRepeatModeOff) {
        [self setRepeatMode:NPAudioStreamRepeatModeAll];
    } else if (self.repeatMode == NPAudioStreamRepeatModeAll) {
        [self setRepeatMode:NPAudioStreamRepeatModeOne];
    } else {
        [self setRepeatMode:NPAudioStreamRepeatModeOff];
    }
}

- (void)incrementShuffleMode {
    if (self.shuffleMode == NPAudioStreamShuffleModeOff) {
        [self setShuffleMode:NPAudioStreamShuffleModeOn];
    } else {
        [self setShuffleMode:NPAudioStreamShuffleModeOff];
    }
}

#pragma mark - Shuffle Logic

- (void)generateShuffleArray {
    NSMutableArray *tempShuffleItems = [NSMutableArray arrayWithArray:_urls];
    [tempShuffleItems shuffle];
    _shuffledURLs = [NSArray arrayWithArray:tempShuffleItems];
}

- (void)generateShuffleArrayWithFirstIndex:(NSInteger)index {
    NSMutableArray *tempShuffleItems = [NSMutableArray arrayWithArray:_urls];
    [tempShuffleItems shuffleWithIndexForItemAsFirstItem:index];
    _shuffledURLs = [NSArray arrayWithArray:tempShuffleItems];
}

#pragma mark - Property Overrides

- (void)setStatus:(NPAudioStreamStatus)status {
    _status = status;
    
    if ([delegate respondsToSelector:@selector(audioStream:didUpdateStatus:)]) {
        [delegate audioStream:self didUpdateStatus:_status];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NPAudioStreamStatusDidChangeNotification
                                                        object:nil];
}

- (void)setUrls:(NSArray *)urls {
    
#ifdef DEBUG
    for (NSURL *url in urls) {
        NSAssert([url scheme], @"Incorrect scheme for URL: %@", url);
    }
#endif
    
    _urls = urls;
    
    [self generateShuffleArray];
    
}

- (void)setRepeatMode:(NPAudioStreamRepeatMode)repeatMode {
    _repeatMode = repeatMode;
    
    if ([delegate respondsToSelector:@selector(audioStream:didUpdateRepeatMode:)]) {
        [delegate audioStream:self didUpdateRepeatMode:_repeatMode];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NPAudioStreamRepeatModeDidChangeNotification
                                                        object:nil];
}

- (void)setShuffleMode:(NPAudioStreamShuffleMode)shuffleMode {
    _shuffleMode = shuffleMode;
    
    if (shuffleMode == NPAudioStreamShuffleModeOn && [_urls containsObject:_currentURL]) {
        NSInteger currentURLIndex = [_urls indexOfObject:_currentURL];
        [self generateShuffleArrayWithFirstIndex:currentURLIndex];
    }
    
    if ([delegate respondsToSelector:@selector(audioStream:didUpdateShuffleMode:)]) {
        [delegate audioStream:self didUpdateShuffleMode:_shuffleMode];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NPAudioStreamShuffleModeDidChangeNotification
                                                        object:nil];
}

- (NSArray *)conditionalURLs {
    return (_shuffleMode == NPAudioStreamShuffleModeOn ? _shuffledURLs : _urls);
}

#pragma mark - Custom Getters for Audio

- (CMTime)currentTime {
    return _player.currentTime;
}

- (CMTime)duration {
    NPPlayerItem *currentItem = (NPPlayerItem *)_player.currentItem;
    return currentItem.verifiedDuration;
}

- (CMTimeRange)loadedTimeRange {
    NPPlayerItem *currentItem = (NPPlayerItem *)_player.currentItem;
    return currentItem.loadedTimeRange;
}

#pragma mark - NPQueuePlayer Delegate

- (void)player:(NPQueuePlayer *)player didChangeRate:(float)rate {
    if (player != _player) return;
    [self setStatus: _player.isPlaying ? NPAudioStreamStatusPlaying : NPAudioStreamStatusPaused];
}

- (void)player:(NPQueuePlayer *)player didSetNewCurrentItem:(NPPlayerItem *)playerItem {
    if (player != _player) return;
    if (playerItem != _player.currentItem) return;
    if (![_urls containsObject:playerItem.url]) return;
    
    if ([delegate respondsToSelector:@selector(audioStream:didLoadTrackAtIndex:)]) {
        [delegate audioStream:self didLoadTrackAtIndex:[_urls indexOfObject:playerItem.url]];
    }
}

#pragma mark - NPPlayerItem Delegate

- (void)playerItem:(NPPlayerItem *)playerItem didChangeLoadedTimeRange:(CMTimeRange)loadedTimeRange {
    
    if (playerItem != _player.currentItem) return;
        
    if ([delegate respondsToSelector:@selector(audioStream:didUpdateTrackLoadedTimeRange:)]) {
        [delegate audioStream:self didUpdateTrackLoadedTimeRange:[self loadedTimeRange]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NPAudioStreamLoadedTimeRangeDidChangeNotification
                                                        object:nil];
    
    NSTimeInterval bufferedSeconds = [self bufferedSecondsForPlayerItem:playerItem];
    
    if (bufferingToResumePlayback && bufferedSeconds > bufferedSecondsWhenPlaybackStopped + requiredBufferToResume) {
        
        [self play];
        [self endBackgroundTask];
        
    }
}

- (void)playerItem:(NPPlayerItem *)playerItem didChangeStatus:(AVPlayerItemStatus)status {
    
    if (playerItem != _player.currentItem) return;

    switch (status) {
        case AVPlayerItemStatusReadyToPlay:
            [self initTimeObservers];
            [self play];
            break;
            
        case AVPlayerItemStatusFailed:
#ifdef DEBUG
            NSLog(@"Failed current NPPlayerItem with error: %@", playerItem.error);
#endif
            //TODO: Handle Player item failure here (e.g. skip to next track, set this track inactive for Core Data library duration?)
            break;
            
        case AVPlayerItemStatusUnknown:
            //TODO: Handle Player item failure here (e.g. skip to next track, set this track inactive for Core Data library duration?)
            break;
    }
}

- (void)playerItem:(NPPlayerItem *)playerItem didChangePlaybackBufferEmpty:(BOOL)playbackBufferEmpty {
    
    if (playerItem != _player.currentItem) return;
        
    if (playbackBufferEmpty) {
        
        [self startBackgroundTask];
        bufferedSecondsWhenPlaybackStopped = [self bufferedSecondsForPlayerItem:playerItem];
        [self setStatus:NPAudioStreamStatusBuffering];
        bufferingToResumePlayback = YES;
        
    }
}

- (void)didPlayToEndTimeForPlayerItem:(NPPlayerItem *)playerItem {
    
    if (playerItem != _player.currentItem) return;
        
    if (_repeatMode == NPAudioStreamRepeatModeOne) {
        if (_player.currentItem != nil) [_player.currentItem seekToTime:kCMTimeZero];
        [_player play];
        return;
    }
    
    [self startBackgroundTask];
    [self skipNext];
    
}

#pragma mark - Buffering Measurement

- (NSTimeInterval)bufferedSecondsForPlayerItem:(NPPlayerItem *)playerItem {
    
    if (playerItem.loadedTimeRanges != nil && playerItem.loadedTimeRanges.count != 0) {
        
        CMTimeRange timeRange = [[playerItem.loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
        Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval bufferedSeconds = startSeconds + durationSeconds;
        return bufferedSeconds;
        
    } else {
        return NAN;
    }
}

#pragma mark - Time Observation

- (void)removeTimeObservers {
    
    if (periodicTimeObserver) {
        [_player removeTimeObserver:periodicTimeObserver];
        periodicTimeObserver = nil;
    }
    
    if (beginningBoundaryTimeObserver) {
        [_player removeTimeObserver:beginningBoundaryTimeObserver];
        beginningBoundaryTimeObserver = nil;
    }
}

- (void)initTimeObservers {
    
    [self removeTimeObservers];
    
    CMTime interval = CMTimeMake(1, 10);
    
    NPPlayerItem *playerItem = (NPPlayerItem *)_player.currentItem;
    CMTime playerDuration = [playerItem verifiedDuration];
    
    if (CMTIME_IS_INVALID(playerDuration) || CMTIME_COMPARE_INLINE(playerDuration, <=, kCMTimeZero)) return;
    
    __weak typeof(self) bself = self;
    periodicTimeObserver = [_player addPeriodicTimeObserverForInterval:interval
                                                                     queue:NULL
                                                                usingBlock: ^(CMTime time) {
                                                                    [bself periodicUpdater];
                                                                }];
    
    NSArray *oneHundredthSecondTime = @[[NSValue valueWithCMTime:CMTimeMake(1, 100)]];
    beginningBoundaryTimeObserver = [_player addBoundaryTimeObserverForTimes:oneHundredthSecondTime
                                                                       queue:NULL
                                                                  usingBlock:^{
                                                                      [bself beganPlaybackForTrack];
                                                                  }];
}

- (void)beganPlaybackForTrack {
    
    [self setStatus:NPAudioStreamStatusPlaying];
    if ([delegate respondsToSelector:@selector(audioStream:didBeginPlaybackForTrackAtIndex:)]) {
        [delegate audioStream:self didBeginPlaybackForTrackAtIndex:[_urls indexOfObject:_currentURL]];
    }
    
    [self endBackgroundTask];
}

- (void)periodicUpdater {
    
    if ([delegate respondsToSelector:@selector(audioStream:didUpdateTrackCurrentTime:)]) {
        [delegate audioStream:self didUpdateTrackCurrentTime:[self currentTime]];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:NPAudioStreamCurrentTimeDidChangeNotification
                                                        object:nil];
}

#pragma mark - Background Task Manager {

- (void)startBackgroundTask {
#if TARGET_OS_IOS
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground &&
        bgTaskID == UIBackgroundTaskInvalid) {

        UIApplication *app = [UIApplication sharedApplication];
        bgTaskID = [app beginBackgroundTaskWithExpirationHandler:^{
            
#ifdef DEBUG
            NSLog(@"Background task timed out.");
#endif
            [self endBackgroundTask];
            
        }];
        
#ifdef DEBUG
        NSLog(@"Began background task.");
#endif
        
    }
#endif
}

- (void)endBackgroundTask {
#if TARGET_OS_IOS
    if (bgTaskID == UIBackgroundTaskInvalid) return;
    
    [[UIApplication sharedApplication] endBackgroundTask:bgTaskID];
    bgTaskID = UIBackgroundTaskInvalid;
    
#ifdef DEBUG
    NSLog(@"Ended background task.");
#endif
#endif
}

@end
