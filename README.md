<p align="center" >
    <img src="http://alexgivens.com/img/npaudiostream-header.png" alt="NPAudioStream" title="NPAudioStream"
</p>

[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/NPAudioStream.svg?style=flat)](http://cocoapods.org/pods/NPAudioStream)
[![License](https://img.shields.io/cocoapods/l/NPAudioStream.svg?style=flat)](http://cocoapods.org/pods/NPAudioStream)
[![Platform](https://img.shields.io/cocoapods/p/NPAudioStream.svg?style=flat)](http://cocoapods.org/pods/NPAudioStream)
[![Twitter](https://img.shields.io/badge/twitter-%40NoonPacific-blue.svg)](http://twitter.com/NoonPacific)

NPAudioStream is a lightweight Objective-C library to continuously stream a playlist of audio on iOS, tvOS, and macOS. NPAudioStream excels at maintaining audio playback over a poor network connection.

## Features

- Audio controls represent the most common music interface behaviors (e.g. play, pause, skip, seek, shuffle).
- Array/index style of url management elegantly binds to table view selection.
- Optionally prebuffer the next track, even when shuffling.
- Detect when a source is not streamable and automatically skip to the next song in the stream.
- Repeat functionality supports one track or the whole stream.
- Shuffle functionality mimics iPod behavior.

#### iOS only

- Manages background tasks to ensure your app remains active during network interruptions
- Pauses and resumes playback in response to a phone call interruption

## Installation

### CocoaPods

The recommended method of installation is through [CocoaPods](http://cocoapods.org). Add the following line to your Podfile, then run `pod install`.

#### Podfile

```ruby
pod 'NPAudioStream', '~> 1.0'
```

For iOS, be sure to [add support for background audio](https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html#//apple_ref/doc/uid/TP40007072-CH4-SW26) as well.

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate NPAudioStream into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "NoonPacific/NPAudioStream" ~> 1.1
```

Run `carthage update` to build the framework and drag the built `NPAudioStream.framework` into your Xcode project.

### Manual Installation

1. [Download NPAudioStream](https://github.com/NoonPacific/NPAudioStream/archive/master.zip)
2. Drag the `NPAudioStream` directory into your Xcode project, and ensure the files are copied into your project's directory.
3. In your Xcode project, navigate to *Target > Build Phases > Link Binary with Libraries* and add the `AVFoundation` framework.
4. For iOS, be sure to [add support for background audio](https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html#//apple_ref/doc/uid/TP40007072-CH4-SW26).

## Basic Example

The simplest usage of NPAudioStream involves creating an instance, populating the `urls` property, then selecting an index for playback. NPAudioStream was built with the intention of streaming [SoundCloud](https://soundcloud.com) audio, so the following example demonstrates how to stream an array of SoundCloud URLs on iOS.

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

NPAudioStream includes a workspace with two example projects - one for macOS and one for iOS (tvOS coming later). These projects showcase the most common patterns to build a music interface.

#### Add your SoundCloud Client ID

These examples use SoundCloud URLs, thus a [SoundCloud Client ID](http://soundcloud.com/you/apps_) is required. In the root directory, duplicate the file named `keys-example.json`, rename the new file to `keys.json`, then add your SC Client ID to `keys.json`.

## Device support

NPAudioStream supports iOS 8.0+, tvOS 9.0+, and macOS 10.8+.

## About

NPAudioStream is created and maintained by [Alex Givens](https://github.com/AlexGivens) for [Noon Pacific](http://noonpacific.com) – the chillest way to discover new music every Monday 🌴

NPAudioStream is released under the MIT license. See LICENSE for details.
