Pod::Spec.new do |s|
  s.name             = 'starxpand_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Star Micronics StarXpand bridge for Shop Staff.'
  s.description      = <<-DESC
Flutter bridge for StarXpand receipt printing using a generic receipt print plan.
DESC
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT', :text => 'MIT License' }
  s.author           = { 'Shop Staff' => 'noreply@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.vendored_frameworks = 'StarIO10.xcframework'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.dependency       'Flutter'
  s.frameworks       = 'UIKit', 'CoreBluetooth', 'ExternalAccessory', 'Network'
  s.static_framework = true
end
