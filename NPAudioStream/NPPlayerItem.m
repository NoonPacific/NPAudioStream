// NPPlayerItem.m
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

#import "NPPlayerItem.h"

/* AVPlayerItem keys */
NSString * kLoadedTimeRangesKey = @"loadedTimeRanges";
NSString * kStatusKey = @"status";
NSString * kPlaybackBufferEmptyKey = @"playbackBufferEmpty";

/* KVO Contexts */
static void *NPPlayerItemLoadedTimeRangesObservationContext = &NPPlayerItemLoadedTimeRangesObservationContext;
static void *NPPlayerItemStatusObservationContext = &NPPlayerItemStatusObservationContext;
static void *NPPlayerItemPlaybackBufferEmptyObservationContext = &NPPlayerItemPlaybackBufferEmptyObservationContext;

@implementation NPPlayerItem

@synthesize delegate;

- (id)initWithAsset:(AVAsset *)asset {
    self = [super initWithAsset:asset];
    if (self) {
        [self subscribeToNotificationsAndObservers];
    }
    return self;
}

- (void)subscribeToNotificationsAndObservers {
    [self addObserver:self
           forKeyPath:kLoadedTimeRangesKey
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:NPPlayerItemLoadedTimeRangesObservationContext];
    [self addObserver:self
           forKeyPath:kPlaybackBufferEmptyKey
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:NPPlayerItemPlaybackBufferEmptyObservationContext];
    [self addObserver:self
           forKeyPath:kStatusKey
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:NPPlayerItemStatusObservationContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didPlayToEndTime:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self];
}

- (void)dealloc {
    [self unsubscribeFromNotificationsAndObservers];
}

- (void)unsubscribeFromNotificationsAndObservers {
    [self removeObserver:self forKeyPath:kLoadedTimeRangesKey];
    [self removeObserver:self forKeyPath:kPlaybackBufferEmptyKey];
    [self removeObserver:self forKeyPath:kStatusKey];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self];
}

- (void)didPlayToEndTime:(NSNotification *)notification {
    if (notification.object != self) return;
    
    if ([delegate respondsToSelector:@selector(didPlayToEndTimeForPlayerItem:)]) {
        [delegate didPlayToEndTimeForPlayerItem:self];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == NPPlayerItemLoadedTimeRangesObservationContext) {
        
        if ([delegate respondsToSelector:@selector(playerItem:didChangeLoadedTimeRange:)]) {
            [delegate playerItem:self didChangeLoadedTimeRange:self.loadedTimeRange];
        }

    }  else if (context == NPPlayerItemStatusObservationContext) {

        if ([delegate respondsToSelector:@selector(playerItem:didChangeStatus:)]) {
            [delegate playerItem:self didChangeStatus:self.status];
        }
        
    } else if (context == NPPlayerItemPlaybackBufferEmptyObservationContext) {
        
        if ([delegate respondsToSelector:@selector(playerItem:didChangePlaybackBufferEmpty:)]) {
            [delegate playerItem:self didChangePlaybackBufferEmpty:self.playbackBufferEmpty];
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (CMTime)verifiedDuration {
    return (self.status == AVPlayerItemStatusReadyToPlay ? self.duration : kCMTimeInvalid);
}

- (CMTimeRange)loadedTimeRange {
    
    NSArray *loadedTimeRanges = self.loadedTimeRanges;
    
    if (loadedTimeRanges && loadedTimeRanges.count) {
        
        CMTimeRange loadedTimeRange = [[loadedTimeRanges firstObject] CMTimeRangeValue];
        return loadedTimeRange;
        
    } else {
        
        return kCMTimeRangeInvalid;
        
    }
}

@end
