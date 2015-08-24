// NPQueuePlayer.m
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
