//
//  NPQueuePlayer.m
//  Noon Pacific
//
//  Created by Alex Givens on 9/22/14.
//  Copyright (c) 2014-2015 Noon Pacific. All rights reserved.
//

#import "NPQueuePlayer.h"
#import "NPPlayerItem.h"

/* AVPlayer keys */
NSString * kCurrentItemKey = @"currentItem";
NSString * kRateKey = @"rate";

/* KVO Contexts */
static void *NPQueuePlayerCurrentItemObservationContext = &NPQueuePlayerCurrentItemObservationContext;
static void *NPQueuePlayerRateObservationContext = &NPQueuePlayerRateObservationContext;

@implementation NPQueuePlayer

@synthesize delegate;

- (id)init {
    self = [super init];
    if (self) {
        [self subscribeToObservers];
    }
    return self;
}

- (id)initWithItems:(NSArray*)items {
    self = [super initWithItems:items];
    if (self) {
        [self subscribeToObservers];
    }
    return self;
}

- (void)subscribeToObservers {
    [self addObserver:self
           forKeyPath:kCurrentItemKey
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:NPQueuePlayerCurrentItemObservationContext];
    [self addObserver:self
           forKeyPath:kRateKey
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:NPQueuePlayerRateObservationContext];
}

- (void)dealloc {
    [self unsubscribeFromObservers];
}

- (void)unsubscribeFromObservers {
    [self removeObserver:self forKeyPath:kCurrentItemKey];
    [self removeObserver:self forKeyPath:kRateKey];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == NPQueuePlayerCurrentItemObservationContext) {
        if ([delegate respondsToSelector:@selector(player:didSetNewCurrentItem:)]) {
            NPPlayerItem *newPlayerItem = (NPPlayerItem *)[change objectForKey:NSKeyValueChangeNewKey];
            if (![newPlayerItem isKindOfClass:[NSNull class]]) {
                [delegate player:self didSetNewCurrentItem:newPlayerItem];
            }
        }
    } else if (context == NPQueuePlayerRateObservationContext) {
        if ([delegate respondsToSelector:@selector(player:didChangeRate:)]) {
            [delegate player:self didChangeRate:self.rate];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Property Overrides

- (BOOL)isPlaying {
    return self.rate != 0.f;
}


@end
