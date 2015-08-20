//
//  NSMutableArray+Extensions.h
//  Color Myx
//
//  Created by Alexander Givens on 9/17/14.
//  Copyright (c) 2014 Jingo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (Extensions)

- (void)shuffle;
- (void)shuffleWithIndexForItemAsFirstItem:(NSUInteger)index;

@end
