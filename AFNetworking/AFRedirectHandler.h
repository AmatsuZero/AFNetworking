// AFRedirectHandler.h
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

NS_ASSUME_NONNULL_BEGIN

/// 控制 HTTP 重定向行为
@protocol AFRedirectHandler <NSObject>

/// 处理重定向
/// @return 要跟随的请求，返回 nil 表示不跟随
- (nullable NSURLRequest *)task:(NSURLSessionTask *)task
              willBeRedirectedTo:(NSURLRequest *)request
                     forResponse:(NSHTTPURLResponse *)response;
@end

/// 重定向行为
typedef NS_ENUM(NSInteger, AFRedirectorBehavior) {
    /// 跟随重定向（不修改请求）
    AFRedirectorBehaviorFollow,
    /// 拒绝重定向
    AFRedirectorBehaviorDoNotFollow,
    /// 使用自定义修改器
    AFRedirectorBehaviorModify,
};

/// 简单重定向策略实现
@interface AFRedirector : NSObject <AFRedirectHandler>

@property (nonatomic, readonly) AFRedirectorBehavior behavior;

+ (instancetype)follower;
+ (instancetype)doNotFollower;
+ (instancetype)modifyWithBlock:(NSURLRequest * _Nullable (^)(NSURLSessionTask *task,
                                                               NSURLRequest *request,
                                                               NSHTTPURLResponse *response))block;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
