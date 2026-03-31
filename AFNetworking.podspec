Pod::Spec.new do |s|
  s.name     = 'AFNetworking'
  s.version  = '4.0.1'
  s.license  = 'MIT'
  s.summary  = 'A delightful networking framework for Apple platforms.'
  s.homepage = 'https://github.com/AFNetworking/AFNetworking'
  s.social_media_url = 'https://twitter.com/AFNetworking'
  s.authors  = { 'Mattt Thompson' => 'm@mattt.me' }
  s.source   = { :git => 'https://github.com/AFNetworking/AFNetworking.git', :tag => s.version }

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.watchos.deployment_target = '6.0'
  s.tvos.deployment_target = '13.0'

  s.pod_target_xcconfig = {
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.alamofire.AFNetworking',
    'SWIFT_STRICT_CONCURRENCY' => 'minimal',
    'OTHER_SWIFT_FLAGS' => '-swift-version 5',
    'DEFINES_MODULE' => 'YES',
    'HEADER_SEARCH_PATHS' => '$(inherited) "${PODS_TARGET_SRCROOT}"'
  }
  s.user_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/Headers/Public/AFNetworking"',
    'OTHER_CFLAGS' => '$(inherited) -Wno-strict-prototypes'
  }
  s.watchos.pod_target_xcconfig = {
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.alamofire.AFNetworking-watchOS'
  }

  s.swift_versions = ['5.5', '5.6', '5.7', '5.8', '5.9', '5.10', '6.0']

  # Note: AFNetworking/AFNetworking.h is not listed here because CocoaPods generates
  # its own umbrella header (AFNetworking-umbrella.h). A compatibility header named
  # AFNetworking.h is provided via the SwiftSupport subspec to satisfy the Swift
  # compiler's generated -Swift.h bridging header import.

  s.subspec 'Serialization' do |ss|
    ss.source_files = 'AFNetworking/AFURL{Request,Response}Serialization.{h,m}'
  end

  s.subspec 'Security' do |ss|
    ss.source_files = 'AFNetworking/AFSecurityPolicy.{h,m}'
  end

  s.subspec 'Reachability' do |ss|
    ss.source_files = 'AFNetworking/AFNetworkReachabilityManager.{h,m}'
  end

  s.subspec 'NSURLSession' do |ss|
    ss.dependency 'AFNetworking/Serialization'
    ss.ios.dependency 'AFNetworking/Reachability'
    ss.osx.dependency 'AFNetworking/Reachability'
    ss.tvos.dependency 'AFNetworking/Reachability'
    ss.dependency 'AFNetworking/Security'

    ss.source_files = 'AFNetworking/AF{URL,HTTP}SessionManager.{h,m}', 'AFNetworking/AFCompatibilityMacros.h'
  end

  s.subspec 'UIKit' do |ss|
    ss.ios.deployment_target = '13.0'
    ss.tvos.deployment_target = '13.0'
    ss.dependency 'AFNetworking/NSURLSession'

    ss.source_files = 'UIKit+AFNetworking'
  end

  s.subspec 'SwiftSupport' do |ss|
    ss.dependency 'AFNetworking/NSURLSession'

    ss.source_files = 'Source/AFSwiftSupport/**/*.{h,m}'
    ss.public_header_files = 'Source/AFSwiftSupport/**/*.h'
  end

  s.subspec 'Swift' do |ss|
    ss.dependency 'AFNetworking/SwiftSupport'

    ss.source_files = 'Source/AFNetworkingSwift/**/*.swift'

    ss.test_spec 'SwiftTests' do |ts|
      ts.source_files = 'Tests/SwiftTests/**/*.swift'
    end
  end
end
