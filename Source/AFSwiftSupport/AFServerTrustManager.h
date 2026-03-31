// AFServerTrustManager.h
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
#import <Security/Security.h>

@class AFSecurityPolicy;

NS_ASSUME_NONNULL_BEGIN

/**
 `AFServerTrustEvaluating` 协议定义服务器信任评估接口。
 对齐 Alamofire 的 `ServerTrustEvaluating` 协议。
 */
NS_SWIFT_NAME(ServerTrustEvaluating)
@protocol AFServerTrustEvaluating <NSObject>

/// 评估服务器信任
/// @param serverTrust 服务器信任对象
/// @param host 主机名
/// @param error 评估失败时的错误输出
/// @return 是否信任
- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                    forHost:(NSString *)host
                      error:(NSError * _Nullable __autoreleasing *)error;

@end

/**
 `AFSecurityPolicyEvaluator` 将现有 `AFSecurityPolicy` 包装为 `AFServerTrustEvaluating` 实现。
 这是桥接旧 API 与新抽象的适配器。
 */
NS_SWIFT_NAME(SecurityPolicyEvaluator)
@interface AFSecurityPolicyEvaluator : NSObject <AFServerTrustEvaluating>

/// 底层安全策略
@property (nonatomic, strong, readonly) AFSecurityPolicy *securityPolicy;

/// 使用安全策略创建
/// @param securityPolicy 安全策略
- (instancetype)initWithSecurityPolicy:(AFSecurityPolicy *)securityPolicy NS_DESIGNATED_INITIALIZER;

+ (instancetype)evaluatorWithSecurityPolicy:(AFSecurityPolicy *)securityPolicy;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

/**
 `AFServerTrustManager` 管理多个 host 的服务器信任评估策略。
 对齐 Alamofire 的 `ServerTrustManager` 设计。
 */
NS_SWIFT_NAME(ServerTrustManager)
@interface AFServerTrustManager : NSObject

/// host -> evaluator 映射
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id<AFServerTrustEvaluating>> *evaluators;

/// 当请求的 host 不在映射中时，是否允许通过。默认 YES（与现有 AFN 行为一致）。
@property (nonatomic, assign) BOOL allUntrustedHostsMustBeEvaluated;

/// 使用 evaluator 映射创建
/// @param evaluators host -> evaluator 映射
- (instancetype)initWithEvaluators:(NSDictionary<NSString *, id<AFServerTrustEvaluating>> *)evaluators NS_DESIGNATED_INITIALIZER;

+ (instancetype)managerWithEvaluators:(NSDictionary<NSString *, id<AFServerTrustEvaluating>> *)evaluators;

/// 获取指定 host 的评估器
/// @param host 主机名
/// @return 评估器，不存在时返回 nil
- (nullable id<AFServerTrustEvaluating>)evaluatorForHost:(NSString *)host;

/// 评估指定 host 的服务器信任
/// @param serverTrust 服务器信任对象
/// @param host 主机名
/// @param error 评估失败时的错误输出
/// @return 是否信任
- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                    forHost:(NSString *)host
                      error:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END