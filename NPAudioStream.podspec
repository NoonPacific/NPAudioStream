Pod::Spec.new do |s|
  s.name     = 'NPAudioStream'
  s.version  = '0.1.4'
  s.license  = 'MIT'
  s.summary  = 'NPAudioStream is an easily controllable, robust audio streaming library for iOS, tvOS, and Mac OS X.'
  s.homepage = 'https://github.com/NoonPacific/NPAudioStream'
  s.social_media_url = 'https://twitter.com/NoonPacific'
  s.authors  = { 'Alex Givens' => 'alex@noonpacific.com' }
  s.source   = { :git => 'https://github.com/NoonPacific/NPAudioStream.git', :tag => s.version }
  s.requires_arc = true

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.8'
  s.tvos.deployment_target = '9.0'

  s.public_header_files = 'NPAudioStream/*.h'
  s.source_files = 'NPAudioStream/NPAudioStream.{h,m}', 'NPAudioStream/NPQueuePlayer.{h,m}', 'NPAudioStream/NPPlayerItem.{h,m}', 'NPAudioStream/Categories/NSURL+Extensions.{h,m}', 'NPAudioStream/Categories/NSMutableArray+Extensions.{h,m}'
  s.ios.source_files = 'NPAudioStream/Categories/UIAlertView+Extensions.{h,m}'
  s.frameworks = 'AVFoundation'
end
