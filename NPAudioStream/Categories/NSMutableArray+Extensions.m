// NSMutableArray+Extensions.m
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

#import "NSMutableArray+Extensions.h"

@implementation NSMutableArray (Extensions)

- (void)shuffle {
    NSInteger count = [self count];
    for (int idx=0; idx<count; idx++) {
        NSInteger remainingCount = count - idx;
        NSInteger exchangeIndex = idx + arc4random_uniform((int)remainingCount);
        [self exchangeObjectAtIndex:idx withObjectAtIndex:exchangeIndex];
    }
}

- (void)shuffleWithIndexForItemAsFirstItem:(NSInteger)index {
    id obj = [self objectAtIndex:index];
    [self shuffle];
    [self exchangeObjectAtIndex:[self indexOfObject:obj] withObjectAtIndex:0];
}

@end
