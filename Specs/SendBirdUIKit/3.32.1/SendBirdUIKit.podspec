Pod::Spec.new do |s|
  s.name = 'SendBirdUIKit'
  s.version = '3.32.1'
  s.summary = 'Sendbird UIKit iOS Framework'
  s.description = 'UIKit module for Sendbird iOS SDK'
  s.homepage = 'https://sendbird.com'
  s.license = { :type => 'Commercial', :file => 'SendBirdUIKit/LICENSE.md' }
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
    :http => 'https://github.com/sendbird/sendbird-uikit-ios/releases/download/3.32.1/SendBirdUIKit.zip',
    :sha1 => '05dbf11b35ff5f32931c353cdf37e8eea94f1107'
  }
  s.requires_arc = true
  s.platform = :ios, '13.0'
  s.documentation_url = 'https://sendbird.com/docs/uikit'
  s.ios.vendored_frameworks = 'SendBirdUIKit/SendbirdUIKit.xcframework'
  s.dependency 'SendbirdChatSDK', '>= 4.29.2'
  s.dependency 'SendbirdUIMessageTemplate', '>= 3.32.1'
  s.ios.frameworks = ['UIKit', 'Foundation', 'CoreData', 'SendbirdChatSDK']
  s.ios.library = 'icucore'
  s.pod_target_xcconfig = { 'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO' }
  s.user_target_xcconfig = { 'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO' }
end
