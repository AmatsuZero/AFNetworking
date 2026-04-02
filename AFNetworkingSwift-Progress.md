# AFNetworkingSwift API 补全总结

## 背景

AFNetworkingSwift 是 AFNetworking 的 Swift 包装层。在与 Alamofire API 对比后，发现一致性约为 40-50%。本次补全在不修改任何 ObjC 代码的前提下，在 Swift 层完成了主要差距的填补。

---

## 本次完成内容（P1 + P2）

### 新建文件

| 文件 | 功能 |
|------|------|
| `Source/AFNetworkingSwift/UploadRequest.swift` | 上传请求类型，继承 DataRequest，新增上传进度回调 |
| `Source/AFNetworkingSwift/MultipartFormData.swift` | Multipart Form Data 的 Swift 门面，包装 ObjC `AFMultipartFormData` 协议 |
| `Source/AFNetworkingSwift/NetworkReachabilityManager.swift` | 网络可达性 Swift wrapper，包装 `AFNetworkReachabilityManager`（watchOS 不可用） |
| `Source/AFNetworkingSwift/CachedResponseHandler.swift` | 缓存响应控制协议 + `ResponseCacher` 具体实现 |
| `Source/AFNetworkingSwift/RedirectHandler.swift` | HTTP 重定向控制协议 + `Redirector` 具体实现 |

### 修改文件

| 文件 | 变更内容 |
|------|---------|
| `Source/AFNetworkingSwift/DownloadRequest.swift` | 新增 `responseData`、`responseString`、`responseDecodable`（从 fileURL 读取并反序列化） |
| `Source/AFNetworkingSwift/DataRequest.swift` | 去掉 `final`，允许 `UploadRequest` 继承 |
| `Source/AFNetworkingSwift/Request.swift` | 新增 `downloadProgressHandler`、`downloadProgress(queue:closure:)`、`authenticate(username:password:)`、`authenticate(with:)` |
| `Source/AFNetworkingSwift/Session.swift` | 新增 `upload(data/file/stream/multipart)`、`download(resumingWith:)`、`cachedResponseHandler`、`redirectHandler`、`setupSessionManagerBlocks()`、`performUploadRequest()`、`performResumedDownloadRequest()` |
| `Source/AFNetworkingSwift/Security/ServerTrustManager.swift` | 新增 `DefaultTrustEvaluator`、`PinnedCertificatesTrustEvaluator`、`PublicKeysTrustEvaluator`、`DisabledTrustEvaluator`、`CompositeTrustEvaluator` |

---

## 当前 API 对齐度

| 模块 | 补全前 | 补全后 |
|------|--------|--------|
| 请求类型 | DataRequest、DownloadRequest | + UploadRequest |
| Session 方法 | request()、download() | + upload(x4)、download(resumingWith:) |
| 响应序列化 | DataRequest 完整 | + DownloadRequest 响应序列化 |
| 进度回调 | 无 | downloadProgress()、uploadProgress() |
| 安全 | SecurityPolicyEvaluator（通用） | + 5 个具体评估器 |
| 网络可达性 | 仅 ObjC 层 | + Swift wrapper |
| 辅助类 | 无 | MultipartFormData、ResponseCacher、Redirector |
| Request 链式方法 | validate()、cURLDescription() | + authenticate(x2)、downloadProgress() |
| Session 生命周期 | 无缓存/重定向控制 | + cachedResponseHandler、redirectHandler |

**估计对齐度：从约 45% 提升至约 75%**

---

## 剩余差距（未完成项）

### P2-4：RetryResult 关联值（Breaking Change）

**现状**：`RetryResult` 是 `Int` RawRepresentable enum，无法表达带延迟重试或携带错误的不重试：
```swift
// 现在
public enum RetryResult: Int { case retry, doNotRetry }

// 目标（对齐 Alamofire）
public enum RetryResult {
    case retry
    case retryWithDelay(TimeInterval)
    case doNotRetry
    case doNotRetryWithError(Error)
}
```

**影响**：所有实现了 `RequestRetrying` 的代码需要同步修改。
**建议**：独立在一个 minor 版本中完成，并提供迁移指南。

---

### P3：命名对齐（Breaking Changes，建议独立 major/minor 版本）

| 现状 | 目标（对齐 Alamofire） | 影响范围 |
|------|----------------------|---------|
| `.GET` `.POST`（大写） | `.get` `.post`（小写） | 所有使用 HTTPMethod 的代码 |
| `RequestIntercepting` | `RequestInterceptor` | 所有自定义拦截器 |
| `RequestAdapting` / `RequestRetrying` | `RequestAdapter` / `RequestRetrier` | 拦截器实现 |
| `DataResponse<Success>` | `DataResponse<Success, Failure>` | 所有响应处理代码 |
| `Session.request(_ String)` | 增加 `URLConvertible` 支持 | 可向后兼容（重载） |

---

## 下一步行动计划

### 第一步：补全测试覆盖

以下功能已实现但缺少对应测试：

```
Tests/SwiftTests/UploadTests.swift       — 上传 Data/File/Multipart，进度回调
Tests/SwiftTests/DownloadTests.swift     — responseData/responseString/responseDecodable，断点续传
Tests/SwiftTests/NetworkReachabilityManagerTests.swift — 可达性状态监听
Tests/SwiftTests/ServerTrustEvaluatorTests.swift — 各评估器行为
Tests/SwiftTests/AuthenticationTests.swift — authenticate() 方法
```

参考路径：`/Users/jiangzhenhua/Github/Alamofire/Tests/` 中对应文件（需适配 AFNetworkingSwift API 差异）。

### 第二步：P2-4 RetryResult 关联值

1. 修改 `Source/AFNetworkingSwift/Core/RetryResult.swift`
2. 同步更新 `Source/AFNetworkingSwift/Interceptor/RequestInterceptor.swift` 中的 retry 回调签名
3. 更新 `AuthenticationInterceptor.swift` 中的 retrier 实现
4. 更新 `Tests/SwiftTests/AuthenticationInterceptorTests.swift`

### 第三步：P3 命名对齐（独立版本）

建议步骤：
1. 先通过 `typealias` 和废弃注解保持向后兼容一个版本
2. 再在下一 major 版本中移除废弃符号
3. HTTPMethod 小写 → 全局替换，影响所有测试文件

### 第四步：DataStreamRequest（可选）

若需要流式响应支持，需要新建 `DataStreamRequest.swift`，但 AFNetworkingSwift 目前没有对应的 ObjC 基础设施，需评估是否值得投入。

---

## 验证命令

```bash
cd /Users/jiangzhenhua/Github/AFNetworking

# 编译 Swift 库
swift build --target AFNetworkingSwift

# 运行 Swift 测试
swift test --filter AFNetworkingSwiftTests

# 运行 ObjC 测试（回归验证）
swift test --filter AFNetworkingTests
```
