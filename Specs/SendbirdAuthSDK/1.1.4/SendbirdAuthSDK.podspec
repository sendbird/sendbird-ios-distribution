
Pod::Spec.new do |s|
  s.name         = 'SendbirdAuthSDK'
  s.version      = "1.1.4"
  s.summary      = 'Sendbird Auth iOS Framework'
  s.description  = 'Authentication module for Sendbird iOS SDK'
  s.homepage     = 'https://sendbird.com'
  s.license      = { :type => 'Commercial', :file => 'SendbirdAuthSDK/LICENSE.md' }
  s.authors      = {
    'Sendbird' => 'sha.sdk_deployment@sendbird.com',
    'Jed Gyeong' => 'jed.gyeong@sendbird.com',
    'Celine Moon' => 'celine.moon@sendbird.com',
    'Tez Park' => 'tez.park@sendbird.com',
    'Damon Park' => 'damon.park@sendbird.com',
    'Young Hwang' => 'young.hwang@sendbird.com',
    'Kai Lee' => 'kai.lee@sendbird.com'
  }
  s.source       = { :http => "https://github.com/sendbird/sendbird-auth-ios/releases/download/1.1.4/SendbirdAuthSDK.zip", :sha1 => "f3e1c2266af5c53007c1df21f56d0aa4ba360058" }
  s.requires_arc = true
  s.platform = :ios, '13.0'
  s.documentation_url = 'https://sendbird.com/docs/chat'
  s.ios.vendored_frameworks = 'SendbirdAuthSDK/SendbirdAuthSDK.xcframework'
  s.pod_target_xcconfig = {
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  s.user_target_xcconfig = {
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  s.ios.frameworks = ['UIKit', 'CFNetwork', 'Security', 'Foundation', 'Network']
end

