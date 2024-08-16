require "json"
package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-wechat-oversea"
  s.version      = "2.4.0"
  s.summary      = "Wechat function,include WeChat Login, Share, Favorite and Payment"
  s.description  = "react-native-wechat-oversea"
  s.author       = { "marvin" => "xiaoyining@heytea.com" }
  s.homepage     = "https://git.heytea.com/react-native-plugs/react-native-wechat"
  s.license      = "MIT"
  s.platform     = :ios, "9.0"
  s.source       =  { :git => package["repository"]["url"], :tag => "#{s.version}" } 
  s.source_files = "ios/**/*.{h,m}"
  s.dependency "React"
  s.requires_arc = true
end
