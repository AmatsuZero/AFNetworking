// AFCachedResponseHandler.h
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "AFCompatibilityMacros.h"

NS_ASSUME_NONNULL_BEGIN

/// 控制响应是否写入缓存
AF_SWIFT_SENDABLE
@protocol AFCachedResponseHandler <NSObject>

/// 决定如何处理缓存响应
/// @return 要缓存的响应（可修改），返回 nil 表示不缓存
- (nullable NSCachedURLResponse *)dataTask:(NSURLSessionDataTask *)task
                         willCacheResponse:(NSCachedURLResponse *)proposedResponse;
@end

/// 缓存行为
typedef NS_ENUM(NSInteger, AFResponseCacherBehavior) {
    /// 按建议缓存
    AFResponseCacherBehaviorCache,
    /// 不缓存
    AFResponseCacherBehaviorDoNotCache,
    /// 使用自定义修改器
    AFResponseCacherBehaviorModify,
};

/// 简单缓存策略实现
AF_SWIFT_SENDABLE
@interface AFResponseCacher : NSObject <AFCachedResponseHandler>

@property (nonatomic, readonly) AFResponseCacherBehavior behavior;

+ (instancetype)cacher;
+ (instancetype)doNotCacher;
+ (instancetype)modifyWithBlock:(NSCachedURLResponse * _Nullable (^)(NSURLSessionDataTask *task,
                                                                      NSCachedURLResponse *proposedResponse))block;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
