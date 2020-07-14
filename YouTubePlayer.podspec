Pod::Spec.new do |s|
  s.name         = "YouTubePlayer"
  s.version      = "0.7.2"
  s.summary      = "Swift library for embedding and controlling YouTube videos in your iOS applications"
  s.homepage     = "https://github.com/gilesvangruisen/Swift-YouTube-Player"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Giles Van Gruisen" => "giles@vangruisen.com" }
  s.social_media_url   = "http://twitter.com/gilesvangruisen"
  s.platform     = :ios, "8.0"
  s.swift_version = '5.0'
  s.source       = { :git => "https://github.com/gilesvangruisen/Swift-YouTube-Player.git", :tag => "v#{s.version}" }
  s.source_files  = "YouTubePlayer/**/*.{swift,h,m}"
  s.exclude_files = "Classes/Exclude"
  s.resources = 'YouTubePlayer/**/*.html'
end
