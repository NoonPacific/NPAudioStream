//
//  MainViewController.m
//  NPAudioStream iOS Example
//
//  Created by Alexander Givens on 8/17/15.
//  Copyright (c) 2015 Noon Pacific. All rights reserved.
//

#import "MainViewController.h"
#import "NPAudioStream.h"

@interface MainViewController () <NPAudioStreamDelegate, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UISlider *seekSlider;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *repeatButton;
@property (weak, nonatomic) IBOutlet UIButton *shuffleButton;

- (IBAction)didChangeValueForSeekSlider:(UISlider *)sender;
- (IBAction)didPressPreviousButton:(id)sender;
- (IBAction)didPressPlayPauseButton:(id)sender;
- (IBAction)didPressNextButton:(id)sender;
- (IBAction)didPressRepeatButton:(id)sender;
- (IBAction)didPressShuffleButton:(id)sender;

@end

@implementation MainViewController {
    NSString *soundcloudToken;
    NSArray *tracks;
    NPAudioStream *audioStream;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *keyDict = [self JSONObjctWithFileName:@"keys"];
    soundcloudToken = [keyDict objectForKey:@"soundcloud_token"];
    
    NSAssert(soundcloudToken.length != 0, @"A valid SoundCloud token is required to stream this playlist. First, generate a valid SoundCloud token from the SoundCloud developer site. Then add the token to the keys.json file in the project root.");

    tracks = [self JSONObjctWithFileName:@"mixtape-151"];
    
    audioStream = [NPAudioStream new];
    [audioStream setDelegate:self];
    
    NSMutableArray *tempURLs = [NSMutableArray arrayWithCapacity:tracks.count];
    
    for (NSDictionary *track in tracks) {
        
        NSString *streamURLstring = [NSString stringWithFormat:@"%@?client_id=%@", [track objectForKey:@"soundcloud_stream_url"], soundcloudToken];
        NSURL *streamURL = [NSURL URLWithString:streamURLstring];
        [tempURLs addObject:streamURL];
    }
    
    [audioStream setUrls:[NSArray arrayWithArray:tempURLs]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return tracks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSDictionary *trackDict = [tracks objectAtIndex:indexPath.row];
    cell.textLabel.text = [trackDict objectForKey:@"title"];
    cell.detailTextLabel.text = [trackDict objectForKey:@"artist"];
    
    return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [audioStream selectIndexForPlayback:indexPath.row];
}

#pragma mark - Button Actions

- (IBAction)didPressPlayPauseButton:(id)sender {
    [self togglePlayPause];
}

- (IBAction)didPressPreviousButton:(id)sender {
    [audioStream skipPrevious];
}

- (IBAction)didPressNextButton:(id)sender {
    [audioStream skipNext];
}

- (IBAction)didPressRepeatButton:(id)sender {
    if (audioStream.repeatMode == NPAudioStreamRepeatModeOff) {
        [audioStream setRepeatMode:NPAudioStreamRepeatModeMix];
    } else if (audioStream.repeatMode == NPAudioStreamRepeatModeMix) {
        [audioStream setRepeatMode:NPAudioStreamRepeatModeTrack];
    } else {
        [audioStream setRepeatMode:NPAudioStreamRepeatModeOff];
    }
}

- (IBAction)didPressShuffleButton:(id)sender {
    if (audioStream.shuffleMode == NPAudioStreamShuffleModeOff) {
        [audioStream setShuffleMode:NPAudioStreamShuffleModeOn];
    } else {
        [audioStream setShuffleMode:NPAudioStreamShuffleModeOff];
    }
}

#pragma mark - Slider Action

- (IBAction)didChangeValueForSeekSlider:(UISlider *)sender {
}

#pragma mark - Audio Stream controllers

- (void)togglePlayPause {
    if (audioStream.status == NPAudioStreamStatusPlaying) {
        [audioStream pause];
    } else if (audioStream.status == NPAudioStreamStatusPaused) {
        [audioStream play];
    }
}

- (void)updatePlaybackProgressView {
    
    CMTime durationTime = audioStream.duration;
    if (CMTIME_IS_INVALID(durationTime)) return;
    CGFloat durationSeconds = CMTimeGetSeconds(durationTime);
    
    CMTime currentTime = audioStream.currentTime;
    
    if (CMTIME_IS_INVALID(currentTime) || CMTIME_COMPARE_INLINE(currentTime, ==, CMTimeMake(0, 1.0))) {
        [self.seekSlider setValue:0.0 animated:NO];
        return;
    }
    
    CGFloat currentSeconds = CMTimeGetSeconds(currentTime);
    
    [self.seekSlider setValue:(currentSeconds/durationSeconds) animated:YES];
    
}

#pragma mark - Audio Stream Delegate

- (void)audioStream:(NPAudioStream *)audioStream didUpdateStatus:(NPAudioStreamStatus)status {
    switch (status) {
        case NPAudioStreamStatusBuffering:
            [self.playPauseButton setTitle:@"Buffering" forState:UIControlStateNormal];
            break;
        case NPAudioStreamStatusPaused:
            [self.playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
            break;
        case NPAudioStreamStatusPlaying:
            [self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

- (void)audioStream:(NPAudioStream *)audioStream didUpdateRepeatMode:(NPAudioStreamRepeatMode)repeatMode {
    switch (repeatMode) {
        case NPAudioStreamRepeatModeOff:
            [self.repeatButton setTitle:@"Repeat Off" forState:UIControlStateNormal];
            break;
        case NPAudioStreamRepeatModeMix:
            [self.repeatButton setTitle:@"Repeat Mix" forState:UIControlStateNormal];
            break;
        case NPAudioStreamRepeatModeTrack:
            [self.repeatButton setTitle:@"Repeat Track" forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

- (void)audioStream:(NPAudioStream *)audioStream didUpdateShuffleMode:(NPAudioStreamShuffleMode)shuffleMode {
    switch (shuffleMode) {
        case NPAudioStreamShuffleModeOff:
            [self.shuffleButton setTitle:@"Shuffle Off" forState:UIControlStateNormal];
            break;
        case NPAudioStreamShuffleModeOn:
            [self.shuffleButton setTitle:@"Shuffle On" forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    
}

- (void)didCompleteAudioStream:(NPAudioStream *)audioStream {
    
}

- (void)didRequestPreviousStreamForAudioStream:(NPAudioStream *)audioStream {
    
}

- (void)audioStream:(NPAudioStream *)audioStream didLoadTrackAtIndex:(NSUInteger)index {
    NSDictionary *track = [tracks objectAtIndex:index];
    self.titleLabel.text = [track objectForKey:@"title"];
    self.artistLabel.text = [track objectForKey:@"artist"];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

- (void)audioStream:(NPAudioStream *)audioStream didBeginPlaybackForTrackAtIndex:(NSUInteger)index {
    
}

- (void)audioStream:(NPAudioStream *)audioStream didUpdateTrackCurrentTime:(CMTime)currentTime {
    [self updatePlaybackProgressView];
}

- (void)audioStream:(NPAudioStream *)audioStream didUpdateTrackLoadedTimeRange:(CMTimeRange)loadedTimeRange {
    
}

- (void)audioStream:(NPAudioStream *)audioStream didFinishSeekingToTime:(CMTime)time {
    
}

- (BOOL)shouldPrebufferNextTrackForAudioStream:(NPAudioStream *)audioStream {
    return YES;
}


#pragma mark - Utility

- (id)JSONObjctWithFileName:(NSString *)fileName {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError* error = nil;
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
}


@end
