//
//  UIAlertView+Extensions.m
//  Color Myx
//
//  Created by Alexander Givens on 11/20/14.
//  Copyright (c) 2014 Jingo. All rights reserved.
//

#import "UIAlertView+Extensions.h"

@implementation UIAlertView (Extensions)

+ (void)showOKAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStyleDefault;
    [alert show];
}

@end
