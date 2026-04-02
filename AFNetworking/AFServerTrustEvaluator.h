// AFServerTrustEvaluator.h
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
#import "AFSecurityPolicy.h"

NS_ASSUME_NONNULL_BEGIN

/// 服务器信任管理错误域
FOUNDATION_EXPORT NSErrorDomain const AFServerTrustErrorDomain;

// MARK: - AFServerTrustEvaluating Protocol

/// 服务器信任评估协议
@protocol AFServerTrustEvaluating <NSObject>

/// 评估服务器信任
/// @return YES 表示通过，NO 表示失败（错误信息写入 error）
- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                    forHost:(NSString *)host
                      error:(NSError **)error;
@end

// MARK: - Concrete Evaluators

/// 将现有 AFSecurityPolicy 包装为 AFServerTrustEvaluating 实现
@interface AFSecurityPolicyEvaluator : NSObject <AFServerTrustEvaluating>
@property (nonatomic, strong, readonly) AFSecurityPolicy *securityPolicy;
- (instancetype)initWithSecurityPolicy:(AFSecurityPolicy *)securityPolicy NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

/// 默认信任评估器：系统证书链验证
@interface AFDefaultTrustEvaluator : NSObject <AFServerTrustEvaluating>
@end

/// 证书 Pinning 评估器
@interface AFPinnedCertificatesTrustEvaluator : NSObject <AFServerTrustEvaluating>
- (instancetype)initWithCertificates:(nullable NSSet<NSData *> *)certificates
              validateCertificateChain:(BOOL)validateCertificateChain NS_DESIGNATED_INITIALIZER;
/// 从 main bundle 加载证书
+ (instancetype)evaluatorWithPinnedCertificates;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

/// 公钥 Pinning 评估器
@interface AFPublicKeysTrustEvaluator : NSObject <AFServerTrustEvaluating>
- (instancetype)initWithCertificates:(nullable NSSet<NSData *> *)certificates NS_DESIGNATED_INITIALIZER;
/// 从 main bundle 加载证书
+ (instancetype)evaluatorWithPinnedKeys;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

/// 禁用信任评估器（仅调试用）
@interface AFDisabledTrustEvaluator : NSObject <AFServerTrustEvaluating>
@end

/// 组合评估器：依次运行多个评估器
@interface AFCompositeTrustEvaluator : NSObject <AFServerTrustEvaluating>
- (instancetype)initWithEvaluators:(NSArray<id<AFServerTrustEvaluating>> *)evaluators NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

// MARK: - AFServerTrustManager

/// 管理多个 host 的服务器信任评估策略
@interface AFServerTrustManager : NSObject
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id<AFServerTrustEvaluating>> *evaluators;
@property (nonatomic, assign) BOOL allHostsMustBeEvaluated;
- (instancetype)initWithEvaluators:(NSDictionary<NSString *, id<AFServerTrustEvaluating>> *)evaluators NS_DESIGNATED_INITIALIZER;
- (nullable id<AFServerTrustEvaluating>)evaluatorForHost:(NSString *)host;
- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forHost:(NSString *)host error:(NSError **)error;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
