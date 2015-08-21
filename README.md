NPAudioStream is an easily controllable, robust audio streaming library for iOS and Mac OS X. 
## Documentation to come

###Example for iOS
####AppDelegate.m
```objective-c
#import "NPAudioStream.h"

@implementation AppDelegate {
    NPAudioStream *audioStream;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    audioStream = [NPAudioStream new];
    
    NSArray *urlStrings = @[@"https://api.soundcloud.com/tracks/216878983/stream",
                            @"https://api.soundcloud.com/tracks/215647717/stream",
                            @"https://api.soundcloud.com/tracks/218064667/stream",
                            @"https://api.soundcloud.com/tracks/206986247/stream"
                            ];
    
    NSMutableArray *urls = [NSMutableArray arrayWithCapacity:urlStrings.count];
    
    for (NSString *urlString in urlStrings) {
        NSString *tokenURLString = [NSString stringWithFormat:@"%@?client_id=SOUNDCLOUD_TOKEN", urlString];
        [urls addObject:[NSURL URLWithString:tokenURLString]];
    }
    
    [audioStream setUrls:urls];
    [audioStream selectIndexForPlayback:0];
    
    return YES;
}

@end
```
