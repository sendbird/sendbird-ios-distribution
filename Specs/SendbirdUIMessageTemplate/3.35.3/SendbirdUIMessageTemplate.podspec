Pod::Spec.new do |s|
  s.name = 'SendbirdUIMessageTemplate'
  s.version = '3.35.3'
  s.summary = 'Sendbird UIMessageTemplate iOS Framework'
  s.description = 'Message template UI module for Sendbird iOS SDK'
  s.homepage = 'https://sendbird.com'
  s.license = { :type => 'Commercial', :file => 'SendbirdUIMessageTemplate/LICENSE.md' }
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
    :http => 'https://github.com/sendbird/sendbird-uikit-ios/releases/download/3.35.3/SendbirdUIMessageTemplate.zip',
    :sha1 => '73d6518f0c1a8bc0d8818e3745f108b4eefccbf6'
  }
  s.requires_arc = true
  s.platform = :ios, '13.0'
  s.documentation_url = 'https://sendbird.com/docs/uikit'
  s.ios.vendored_frameworks = 'SendbirdUIMessageTemplate/SendbirdUIMessageTemplate.xcframework'
  s.dependency 'SendbirdChatSDK', '>= 4.39.4'
  s.ios.frameworks = ['UIKit', 'Foundation', 'CoreData', 'SendbirdChatSDK']
  s.ios.library = 'icucore'
  s.pod_target_xcconfig = { 'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO' }
  s.user_target_xcconfig = { 'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO' }
end
