//
//  NPQueuePlayer.h
//  Noon Pacific
//
//  Created by Alex Givens on 9/22/14.
//  Copyright (c) 2014-2015 Noon Pacific. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@class NPQueuePlayer;
@class NPPlayerItem;

@protocol NPQueuePlayerDelegate <NSObject>
@optional

- (void)player:(NPQueuePlayer *)player didChangeRate:(float)rate;
- (void)player:(NPQueuePlayer *)player didSetNewCurrentItem:(NPPlayerItem *)playerItem;

@end

@interface NPQueuePlayer : AVQueuePlayer {
    __weak id <NPQueuePlayerDelegate> delegate;
}

@property (nonatomic, weak) id <NPQueuePlayerDelegate> delegate;
@property (nonatomic, readonly, getter=isPlaying) BOOL playing;

@end
