#
# Be sure to run `pod lib lint com.awareframework.ios.sensor.accelerometer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'com.awareframework.ios.sensor.accelerometer'
  s.version          = '0.6.0'
  s.summary          = 'An Accelerometer Sensor Module for AWARE Framework'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This sensor module allows us to manage 3-axis accelerometer data which is provided by iOS CoreMotion Library. Please check the link below for details. 
                       DESC

  s.homepage         = 'https://github.com/awareframework/com.awareframework.ios.sensor.accelerometer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'Apache2', :file => 'LICENSE' }
  s.author           = { 'Yuuki Nishiyama' => 'yuukin@iis.u-tokyo.ac.jp' }
  s.source           = { :git => 'https://github.com/awareframework/com.awareframework.ios.sensor.accelerometer.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/tetujin23'

  s.ios.deployment_target = '11.0'
  
  s.swift_version = '4.2'

  s.source_files = 'com.awareframework.ios.sensor.accelerometer/Classes/**/*'
  
  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'CoreMotion'
  s.dependency 'com.awareframework.ios.sensor.core', '~> 0.6.1'
end
