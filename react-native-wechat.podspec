Pod::Spec.new do |s|
  s.name         = "react-native-wechat"
  s.version      = "1.0.1"
  s.summary      = "Wechat function,include WeChat Login, Share, Favorite and Payment"
  s.description  = "react-native-wechat"
  s.author       = { "marvin" => "xiaoyining@heytea.com" }
  s.homepage     = "https://git.heytea.com/react-native-plugs/react-native-wechat"
  s.license      = "MIT"
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://git.heytea.com/react-native-plugs/react-native-wechat.git", :tag => "master" }
  s.source_files = "ios/**/*.{h,m}"
  s.dependency "React"
  s.dependency 'WechatOpenSDK-XCFramework'
  s.requires_arc = true
end
