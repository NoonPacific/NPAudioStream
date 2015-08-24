//  MainViewController.m
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

#import "MainViewController.h"
#import "NPAudioStream.h"

@interface MainViewController () <NPAudioStreamDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UISlider *seekSlider;
@property (weak, nonatomic) IBOutlet UIButton *previousButton;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *repeatButton;
@property (weak, nonatomic) IBOutlet UIButton *shuffleButton;

- (IBAction)didChangeValueForSeekSlider:(UISlider *)sender;
- (IBAction)didPressButton:(UIButton *)sender;

@end

@implementation MainViewController {
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table View Data Source

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
    
    return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [audioStream selectIndexForPlayback:indexPath.row];
}

#pragma mark - Button Actions

- (IBAction)didPressButton:(UIButton *)sender {
    if (sender == self.previousButton)
        [audioStream skipPrevious];
    else if (sender == self.playPauseButton)
        [self togglePlayPause];
    else if (sender == self.nextButton)
        [audioStream skipNext];
    else if (sender == self.shuffleButton)
        [audioStream incrementShuffleMode];
    else if (sender == self.repeatButton)
        [audioStream incrementRepeatMode];
}

#pragma mark - Slider Action

- (IBAction)didChangeValueForSeekSlider:(UISlider *)sender {
    // TODO: Seek slider control
}

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

- (void)updateSeekSliderValue {
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

- (void)updateRepeatModeButtonTitle {
    switch (audioStream.repeatMode) {
        case NPAudioStreamRepeatModeOff:
            [self.repeatButton setTitle:@"Repeat Off" forState:UIControlStateNormal];
            break;
        case NPAudioStreamRepeatModeMix:
            [self.repeatButton setTitle:@"Repeat All" forState:UIControlStateNormal];
            break;
        case NPAudioStreamRepeatModeTrack:
            [self.repeatButton setTitle:@"Repeat One" forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

- (void)updateShuffleModeButtonTitle {
    switch (audioStream.shuffleMode) {
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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Audio Stream Complete"
                                                    message:@"At this point, we can implement logic to load the next playlist."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStyleDefault;
    [alert show];
}

- (void)didRequestPreviousStreamForAudioStream:(NPAudioStream *)audioStream {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Previous Audio Stream Requested"
                                                    message:@"At this point, we can implement logic to load the previous playlist."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStyleDefault;
    [alert show];
}

- (void)audioStream:(NPAudioStream *)audioStream didLoadTrackAtIndex:(NSUInteger)index {
    NSDictionary *track = [tracks objectAtIndex:index];
    self.titleLabel.text = [track objectForKey:@"title"];
    self.artistLabel.text = [track objectForKey:@"artist"];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

- (void)audioStream:(NPAudioStream *)audioStream didUpdateTrackCurrentTime:(CMTime)currentTime {
    [self updateSeekSliderValue];
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
