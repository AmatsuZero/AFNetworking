// AlamofireTestMapping.md
# Alamofire 测试映射清单

基线提交: `36f1747e31305e0cfda27864091318950c66a5b1`

## 测试分类

### ✅ 可直接复用（语义等价，仅需替换 import 和类型名）

| Alamofire 测试文件 | 对应 AFNetworkingSwift 测试 | 覆盖能力 |
|---|---|---|
| `SessionTests.swift` (基本请求部分) | `SessionTests.swift` | GET/POST/PUT/DELETE/PATCH 请求创建与响应 |
| `ValidationTests.swift` | `ValidationTests.swift` | 状态码验证、Content-Type 验证、自定义验证 |
| `ResponseSerializationTests.swift` (Data/String/JSON) | `SessionTests.swift` (响应序列化部分) | responseData/responseString/responseJSON |
| `DecodableResponseSerializerTests.swift` | `SessionTests.swift` (Decodable 部分) | responseDecodable |

### 🔧 需适配后复用（依赖 Alamofire 内部类型，需提供替身或映射）

| Alamofire 测试文件 | 适配说明 |
|---|---|
| `RequestInterceptorTests.swift` | 需将 `Alamofire.Interceptor` 替换为 `AFNetworkingSwift.Interceptor` |
| `RetryPolicyTests.swift` | 需将 `Alamofire.RetryPolicy` 替换为 `AFNetworkingSwift.RetryPolicy` |
| `AuthenticationInterceptorTests.swift` | 需提供 `TestAuthenticator` 替身实现 |
| `EventMonitorTests.swift` | 需将 `ClosureEventMonitor` 映射到 OC 层 `AFClosureEventMonitor` |
| `ServerTrustEvaluationTests.swift` | 需将 `ServerTrustManager` 映射到 `AFServerTrustManager` |
| `DownloadTests.swift` | 需适配 `DownloadDestination` 类型差异 |
| `ConcurrencyTests.swift` | 需适配 async/await API 签名差异 |

### ❌ 无法复用（依赖 Alamofire 私有实现或不适用的能力）

| Alamofire 测试文件 | 原因 | 替代策略 |
|---|---|---|
| `URLEncodedFormEncoderTests.swift` | AFN 使用自己的 `AFURLRequestSerialization` | 复用现有 AFN OC 测试 |
| `MultipartFormDataTests.swift` | AFN 使用自己的 multipart 实现 | 复用现有 AFN OC 测试 |
| `URLProtocolTests.swift` | 依赖 Alamofire 内部 URLProtocol 注册机制 | 需补写等价测试 |
| `NetworkReachabilityManagerTests.swift` | AFN 有自己的 `AFNetworkReachabilityManager` | 复用现有 AFN OC 测试 |
| `CacheTests.swift` | 依赖 Alamofire 内部缓存处理器 | 后续版本补齐 |
| `RedirectHandlerTests.swift` | 依赖 Alamofire 内部重定向处理器 | 后续版本补齐 |

## 测试失败归因机制

测试失败时按以下优先级归因：

1. **包装器实现缺陷**：Swift 包装层逻辑错误，如回调未触发、状态不一致
2. **AFNetworking 底层限制**：底层 OC 能力不支持某一行为，如缺少 per-request 缓存控制
3. **测试适配问题**：测试本身依赖 Alamofire 特有类型或行为，需要适配层调整

## 核心测试覆盖矩阵

| 能力 | 测试状态 |
|---|---|
| 请求创建 (GET/POST/PUT/DELETE/PATCH) | ✅ 已覆盖 |
| 参数编码 | 🔧 复用 AFN OC 测试 |
| 响应序列化 (Data/String/JSON/Decodable) | ✅ 已覆盖 |
| 响应验证 (状态码/Content-Type/自定义) | ✅ 已覆盖 |
| 拦截器 (Adapter/Retrier/Interceptor) | 🔧 需适配 |
| 重试策略 | 🔧 需适配 |
| 认证拦截器 | 🔧 需适配 |
| 下载请求 | 🔧 需适配 |
| async/await | 🔧 需适配 |
| 事件监控 | 🔧 需适配 |
| 服务器信任管理 | 🔧 需适配 |
| 请求取消 | ✅ 已覆盖 |
| 自定义头 | ✅ 已覆盖 |