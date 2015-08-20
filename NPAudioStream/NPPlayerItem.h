//
//  NPPlayerItem.h
//  Noon Pacific
//
//  Created by Alex Givens on 9/22/14.
//  Copyright (c) 2014-2015 Noon Pacific. All rights reserved.
//

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
