#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
    s.name             = 'flutter_tts'
    s.version          = '0.0.1'
    s.summary          = 'macOS implementation of the flutter_tts plugin.'
    s.description      = <<-DESC
  A flutter text to speech plugin
                         DESC
    s.homepage         = 'https://github.com/dlutton/flutter_tts'
    s.license          = { :file => '../LICENSE' }
    s.author           = { 'Daniel Lutton' => 'eyedea32@gmail.com' }
    s.source           = { :path => '.' }
    s.source_files = 'Classes/**/*'
    s.dependency 'FlutterMacOS'
  
    s.platform = :osx, '10.15'
    s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
    s.swift_version = '5.0'
  
  end