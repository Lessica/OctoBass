#
# Be sure to run `pod lib lint OctoBass.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OctoBass'
  s.version          = '0.1.0'
  s.summary          = 'A short description of OctoBass.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
DESC

  s.homepage         = 'https://github.com/Lessica/OctoBass'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Lessica' => '5410705+Lessica@users.noreply.github.com' }
  s.source           = { :git => 'https://github.com/Lessica/OctoBass.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/82Flex'

  s.ios.deployment_target = '9.0'

  s.source_files = 'OctoBass/Classes/**/*'
  s.resource_bundles = {
    'OctoBass' => ['OctoBass/Assets/*.js']
  }
  s.private_header_files = 'OctoBass/Classes/**/*.h'
  s.frameworks = 'UIKit', 'WebKit', 'AVFoundation', 'AVKit', 'MediaPlayer'

  s.dependency 'Protobuf', '>= 3.11.1'
  s.dependency 'FMDB', '~> 2.7.5'
end
