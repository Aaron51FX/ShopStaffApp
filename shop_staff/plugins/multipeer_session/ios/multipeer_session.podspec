Pod::Spec.new do |s|
  s.name             = 'multipeer_session'
  s.version          = '0.0.1'
  s.summary          = 'Lightweight P2P bridge for dual-screen ordering.'
  s.description      = <<-DESC
Bridge for Multipeer Connectivity on iOS (advertise/browse/send/receive) with a stub on Android.
DESC
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT', :text => 'MIT License' }
  s.author           = { 'Your Company' => 'example@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'
  s.dependency       'Flutter'
  s.framework        = 'MultipeerConnectivity'
  s.static_framework = true
end
