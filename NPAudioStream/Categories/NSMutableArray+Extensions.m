//
//  NSMutableArray+Extensions.m
//  Color Myx
//
//  Created by Alexander Givens on 9/17/14.
//  Copyright (c) 2014 Jingo. All rights reserved.
//

#import "NSMutableArray+Extensions.h"

@implementation NSMutableArray (Extensions)

- (void)shuffle {
    NSUInteger count = [self count];
    for (int idx=0; idx<count; idx++) {
        NSInteger remainingCount = count - idx;
        NSInteger exchangeIndex = idx + arc4random_uniform((int)remainingCount);
        [self exchangeObjectAtIndex:idx withObjectAtIndex:exchangeIndex];
    }
}

- (void)shuffleWithIndexForItemAsFirstItem:(NSUInteger)index {
    id obj = [self objectAtIndex:index];
    [self shuffle];
    [self exchangeObjectAtIndex:[self indexOfObject:obj] withObjectAtIndex:0];
}

@end
