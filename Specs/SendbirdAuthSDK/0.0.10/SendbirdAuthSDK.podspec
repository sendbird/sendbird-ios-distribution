Pod::Spec.new do |s|
  s.name = 'SendbirdAuthSDK'
  s.version = '0.0.10'
  s.summary = 'Sendbird Auth iOS Framework'
  s.description = 'Authentication module for Sendbird iOS SDK'
  s.homepage = 'https://sendbird.com'
  s.license = { :type => 'Commercial', :file => 'SendbirdAuthSDK/LICENSE.md' }
  s.authors = {
    'Sendbird' => 'sha.sdk_deployment@sendbird.com',
    'Jed Gyeong' => 'jed.gyeong@sendbird.com',
    'Celine Moon' => 'celine.moon@sendbird.com',
    'Tez Park' => 'tez.park@sendbird.com',
    'Damon Park' => 'damon.park@sendbird.com',
    'Young Hwang' => 'young.hwang@sendbird.com',
    'Kai Lee' => 'kai.lee@sendbird.com'
  }
  s.source = {
    :http => 'https://github.com/sendbird/sendbird-auth-ios/releases/download/0.0.10/SendbirdAuthSDK.zip',
    :sha1 => 'fbaca18a4690b8e573c5c5c31fe97b8fd0c424a7'
  }
  s.requires_arc = true
  s.ios.deployment_target = '13.0'
  s.documentation_url = 'https://sendbird.com/docs/chat'
  s.ios.vendored_frameworks = 'SendbirdAuthSDK/SendbirdAuthSDK.xcframework'
  s.ios.frameworks = 'UIKit', 'CFNetwork', 'Security', 'Foundation', 'Network'
  s.pod_target_xcconfig = { 'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO' }
  s.user_target_xcconfig = { 'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO' }
end
