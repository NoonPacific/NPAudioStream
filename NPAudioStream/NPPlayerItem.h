// NPPlayerItem.h
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

@class NPPlayerItem;

@protocol NPPlayerItemDelegate <NSObject>
@optional

- (void)playerItem:(NPPlayerItem *)playerItem didChangeLoadedTimeRange:(CMTimeRange)loadedTimeRange;
- (void)playerItem:(NPPlayerItem *)playerItem didChangeStatus:(AVPlayerItemStatus)status;
- (void)playerItem:(NPPlayerItem *)playerItem didChangePlaybackBufferEmpty:(BOOL)playbackBufferEmpty;
- (void)didPlayToEndTimeForPlayerItem:(NPPlayerItem *)playerItem;

@end

@interface NPPlayerItem : AVPlayerItem {
    __weak id <NPPlayerItemDelegate> delegate;
}

@property (nonatomic, weak) id <NPPlayerItemDelegate> delegate;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, readonly) CMTime verifiedDuration;
@property (nonatomic, readonly) CMTimeRange loadedTimeRange;

- (id)initWithAsset:(AVAsset *)asset;

@end
