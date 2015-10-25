//  RootViewController.m
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

#import "RootViewController.h"
#import "NPAudioStream.h"

@interface RootViewController () <NPAudioStreamDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *titleTextField;
@property (weak) IBOutlet NSTextField *artistTextField;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSButton *previousButton;
@property (weak) IBOutlet NSButton *playPauseButton;
@property (weak) IBOutlet NSButton *nextButton;
@property (weak) IBOutlet NSButton *repeatButton;
@property (weak) IBOutlet NSButton *shuffleButton;

- (IBAction)didPressButton:(NSButton *)sender;

@end

@implementation RootViewController {
    NSString *soundCloudClientID;
    NSArray *tracks;
    NPAudioStream *audioStream;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *keyDict = [self JSONObjectWithFileName:@"keys"];
    soundCloudClientID = [keyDict objectForKey:@"soundcloud_client_id"];
    
    NSAssert(soundCloudClientID.length != 0, @"A valid SoundCloud Client ID is required to stream this playlist, attainable from the SoundCloud developer website. Make sure the SC Client ID is then added to the keys.json file in the project root.");
    
    // Use of the mixtape-151.json file is representative of an incoming JSON array from network
    tracks = [self JSONObjectWithFileName:@"mixtape-151"];
    
    audioStream = [NPAudioStream new];
    [audioStream setDelegate:self];
    
    NSMutableArray *urls = [NSMutableArray arrayWithCapacity:tracks.count];
    
    for (NSDictionary *track in tracks) {
        NSString *streamURLString = [NSString stringWithFormat:@"%@?client_id=%@", [track objectForKey:@"soundcloud_stream_url"], soundCloudClientID];
        NSURL *url = [NSURL URLWithString:streamURLString];
        [urls addObject:url];
    }
    
    [audioStream setUrls:urls];
    
    [self updateRepeatModeButtonTitle];
    [self updateShuffleModeButtonTitle];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return tracks.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTextField *result = [tableView makeViewWithIdentifier:@"MyView" owner:self];
    
    NSDictionary *trackDict = [tracks objectAtIndex:row];
    result.stringValue = [trackDict objectForKey:@"title"];
    
    return result;
}

#pragma mark - Table View Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableView = notification.object;
    [audioStream selectIndexForPlayback:(long)tableView.selectedRow];
}

#pragma mark - Button Actions

- (void)didPressButton:(NSButton *)sender {
    if (sender == self.previousButton)
        [audioStream skipPrevious];
    else if (sender == self.playPauseButton)
        [self togglePlayPause];
    else if (sender == self.nextButton)
        [audioStream skipNext];
    else if (sender == self.repeatButton)
        [audioStream incrementRepeatMode];
    else if (sender == self.shuffleButton)
        [audioStream incrementShuffleMode];
}


#pragma mark - Slider Action

// TODO: Add a slider to showcase seek functionality

#pragma mark - Custom Audio Stream Controllers

- (void)togglePlayPause {
    if (audioStream.status == NPAudioStreamStatusPlaying) {
        [audioStream pause];
    } else if (audioStream.status == NPAudioStreamStatusPaused) {
        [audioStream play];
    }
}

#pragma mark - Interface Controllers

- (void)updatePlayPauseButtonTitle {
    switch (audioStream.status) {
        case NPAudioStreamStatusBuffering:
            [self.playPauseButton setTitle:@"Buffering"];
            break;
        case NPAudioStreamStatusPaused:
            [self.playPauseButton setTitle:@"Play"];
            break;
        case NPAudioStreamStatusPlaying:
            [self.playPauseButton setTitle:@"Pause"];
            break;
        default:
            break;
    }
}

- (void)updateProgressIndicator {
    CMTime durationTime = audioStream.duration;
    if (CMTIME_IS_INVALID(durationTime)) return;
    CGFloat durationSeconds = CMTimeGetSeconds(durationTime);
    CMTime currentTime = audioStream.currentTime;
    
    if (CMTIME_IS_INVALID(currentTime) || CMTIME_COMPARE_INLINE(currentTime, ==, CMTimeMake(0, 1.0))) {
        [self.progressIndicator setDoubleValue:0.0];
        return;
    }
    
    CGFloat currentSeconds = CMTimeGetSeconds(currentTime);
    [self.progressIndicator setDoubleValue:(currentSeconds/durationSeconds)];
}

- (void)updateRepeatModeButtonTitle {
    switch (audioStream.repeatMode) {
        case NPAudioStreamRepeatModeOff:
            [self.repeatButton setTitle:@"Repeat Off"];
            break;
        case NPAudioStreamRepeatModeMix:
            [self.repeatButton setTitle:@"Repeat Mix"];
            break;
        case NPAudioStreamRepeatModeTrack:
            [self.repeatButton setTitle:@"Repeat Track"];
            break;
        default:
            break;
    }
}

- (void)updateShuffleModeButtonTitle {
    switch (audioStream.shuffleMode) {
        case NPAudioStreamShuffleModeOff:
            [self.shuffleButton setTitle:@"Shuffle Off"];
            break;
        case NPAudioStreamShuffleModeOn:
            [self.shuffleButton setTitle:@"Shuffle On"];
            break;
        default:
            break;
    }
}

#pragma mark - Audio Stream Delegate

- (void)audioStream:(NPAudioStream *)audioStream didUpdateStatus:(NPAudioStreamStatus)status {
    [self updatePlayPauseButtonTitle];
}

- (void)audioStream:(NPAudioStream *)audioStream didUpdateRepeatMode:(NPAudioStreamRepeatMode)repeatMode {
    [self updateRepeatModeButtonTitle];
}

- (void)audioStream:(NPAudioStream *)audioStream didUpdateShuffleMode:(NPAudioStreamShuffleMode)shuffleMode {
    [self updateShuffleModeButtonTitle];
}

- (void)didCompleteAudioStream:(NPAudioStream *)audioStream {
    NSAlert *alert = [NSAlert new];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:@"Audio Stream Complete"];
    [alert setInformativeText:@"At this point, we can implement logic to load the next playlist."];
    [alert runModal];
}

- (void)didRequestPreviousStreamForAudioStream:(NPAudioStream *)audioStream {
    NSAlert *alert = [NSAlert new];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:@"Previous Audio Stream Requested"];
    [alert setInformativeText:@"At this point, we can implement logic to load the previous playlist."];
    [alert runModal];
}

- (void)audioStream:(NPAudioStream *)audioStream didLoadTrackAtIndex:(NSInteger)index {
    NSDictionary *track = [tracks objectAtIndex:index];
    self.titleTextField.stringValue = [track objectForKey:@"title"];
    self.artistTextField.stringValue = [track objectForKey:@"artist"];
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    [self.tableView selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (void)audioStream:(NPAudioStream *)audioStream didUpdateTrackCurrentTime:(CMTime)currentTime {
    [self updateProgressIndicator];
}

- (void)audioStream:(NPAudioStream *)audioStream didUpdateTrackLoadedTimeRange:(CMTimeRange)loadedTimeRange {
    // TODO: Buffer indicator
}

- (void)audioStream:(NPAudioStream *)audioStream didFinishSeekingToTime:(CMTime)time {
    // TODO: Seek slider control
}

- (BOOL)shouldPrebufferNextTrackForAudioStream:(NPAudioStream *)audioStream {
    return YES;
}

#pragma mark - Utility

- (id)JSONObjectWithFileName:(NSString *)fileName {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError* error = nil;
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
}

@end
