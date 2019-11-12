#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_tts'
  s.version          = '0.0.1'
  s.summary          = 'A flutter text to speech plugin.'
  s.description      = <<-DESC
A flutter text to speech plugin
                       DESC
  s.homepage         = 'https://github.com/dlutton/flutter_tts'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'tundralabs' => 'eyedea32@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.ios.deployment_target = '8.0'
  s.swift_version = '4.2'
  s.static_framework = true
end

