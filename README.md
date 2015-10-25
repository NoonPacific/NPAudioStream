<p align="center" >
    <img src="http://alexgivens.com/npaudiostream-header.png" alt="NPAudioStream" title="NPAudioStream"
</p>

NPAudioStream is an easily controllable, robust audio streaming library for iOS, tvOS, and Mac OS X. It was built to interface a playlist of remote audio with standard music UI components.

## Features

- Audio controls represent the most common music interface behaviors (e.g. play, pause, skip, seek, shuffle, etc.)
- Array/index style of url management elegantly binds to table view display and selection commands
- Optionally prebuffer the next track, even when shuffling
- Detects when a source is not streamable and automatically skips to the next song in the queue
- Repeat functionality supports single, all, or off
- Shuffle functionality mimics iPod behavior

#### iOS Specific

- Manages background tasks to ensure your app remains active during network interruptions
- Pauses and resumes playback in response to a phone call interruption

## Installation

### CocoaPods

The recommended method of installation is through [CocoaPods](http://cocoapods.org). Add the following line to your Podfile, then run `pod install`.

For iOS, be sure to [add support for background audio](https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html#//apple_ref/doc/uid/TP40007072-CH4-SW26).

#### Podfile

```ruby
pod 'NPAudioStream', :git => 'https://github.com/NoonPacific/NPAudioStream.git'
```

### Manual Installation

1. [Download NPAudioStream](https://github.com/NoonPacific/NPAudioStream/archive/master.zip)
2. Drag the `NPAudioStream` directory into your Xcode project, and ensure the files are copied into your project's directory.
3. In your Xcode project, navigate to *Target > Build Phases > Link Binary with Libraries* and add the `AVFoundation` framework.
4. For iOS, be sure to [add support for background audio](https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html#//apple_ref/doc/uid/TP40007072-CH4-SW26).

## Basic Code Example

The simplest usage of NPAudioStream involves creating an instance, populating the `urls` property, then selecting an index for playback. NPAudioStream was built with the intention of streaming [SoundCloud](https://soundcloud.com) audio, so the following example demonstrates how to stream a playlist of SoundCloud URLs on iOS.

**Note: Be sure to replace `YOUR_CLIENT_ID` with your own [SoundCloud Client ID](http://soundcloud.com/you/apps_).**

#### AppDelegate.m

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

    // append SoundCloud Client ID and create NSURL objects
    for (NSString *urlString in urlStrings) {
        NSString *streamURLString = [NSString stringWithFormat:@"%@?client_id=YOUR_CLIENT_ID", urlString];
        NSURL *url = [NSURL URLWithString:streamURLString];
        [urls addObject:url];
    }

    [audioStream setUrls:urls];
    [audioStream selectIndexForPlayback:0];

    return YES;
}

@end
```

## Example Projects

NPAudioStream includes a workspace with two example projects - one for Mac and one for iOS (tvOS coming later). These projects showcase the most common patterns to build a music interface.

#### Add your SoundCloud Client ID

These examples use SoundCloud URLs, thus a [SoundCloud Client ID](http://soundcloud.com/you/apps_) is required. In the root directory, duplicate the file named `keys-example.json`, rename the new file to `keys.json`, then add your SC Client ID to `keys.json`.

## Device support

NPAudioStream supports iOS 8.0+, tvOS 9.0+, and Mac OSX 10.8+.

## About

NPAudioStream is created and maintained by [Alex Givens](https://github.com/AlexGivens) for [Noon Pacific](http://noonpacific.com) – the chillest way to discover new music every Monday 🌴

NPAudioStream is released under the MIT license. See LICENSE for details.
