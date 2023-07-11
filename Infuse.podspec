Pod::Spec.new do |s|
  s.name             = 'Infuse'
  s.version          = '0.0.2'
  s.summary          = 'A lightweight dependency injection library'
  s.homepage         = 'https://github.com/Kevinvandenhoek/Infuse.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Kevin van den Hoek' => 'kevinvandenhoek@gmail.com' }
  s.source           = { :git => 'https://github.com/Kevinvandenhoek/Infuse.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/Infuse/**/*'
end
