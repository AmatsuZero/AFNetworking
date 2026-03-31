# 发布验收基线

## 版本阶段定义

### MVP（最小可行版本）

**目标**：Swift 用户可以使用类 Alamofire 风格的 API 发送请求、处理响应、进行基本验证。

**交付范围**：
- [x] OC 支撑层：AFHTTPMethod、AFHTTPHeaders、AFRequestDescriptor、AFRequestContext
- [x] OC 支撑层：AFRequestInterceptor（协议 + Block 实现）
- [x] OC 支撑层：AFDataResponse、AFDownloadResponse
- [x] OC 支撑层：AFResponseValidator（状态码 + Content-Type + Block）
- [x] OC 支撑层：AFEventMonitor（协议 + 组合 + 闭包）
- [x] OC 支撑层：AFServerTrustManager
- [x] Swift 层：Session、Request、DataRequest、DownloadRequest
- [x] Swift 层：DataResponse<T>、DownloadResponse<T>
- [x] Swift 层：validate()、responseData/String/JSON/Decodable
- [x] Swift 层：async/await 支持
- [x] Swift 层：AFError 统一错误类型
- [x] 构建集成：CocoaPods subspec（SwiftSupport + Swift）
- [x] 构建集成：SwiftPM target（AFSwiftSupport + AFNetworkingSwift）
- [x] 测试：核心 Session/Validation 测试
- [x] 测试：兼容性回归测试
- [x] 文档：Alamofire 测试映射清单

**成功标准**：
1. API 可用性：Swift 用户可以通过 `AF.request(...)` 发起请求并获得类型安全的响应
2. 兼容性：现有 OC 用户 `pod 'AFNetworking'` 不受影响，无 break change
3. 测试通过率：核心测试（请求创建、响应序列化、验证）100% 通过
4. 迁移成本：Swift 用户从 Alamofire 迁移只需替换 import 和少量类型名

### 增强版本

**目标**：补齐高级拦截、认证恢复、重试策略、事件监控等能力。

**交付范围**：
- [x] Swift 层：AuthenticationInterceptor
- [x] Swift 层：RetryPolicy
- [x] Swift 层：Interceptor 组合实现
- [ ] 适配更多 Alamofire 测试（拦截器、重试、认证、下载、并发）
- [ ] 补齐 per-request 拦截器在执行管线中的完整集成
- [ ] 补齐 cURL 调试输出的完整实现

### 后续扩展版本

**目标**：覆盖缓存处理、重定向处理、Upload 请求等完整能力。

**交付范围**：
- [ ] AFCachedResponseHandler
- [ ] AFRedirectHandler
- [ ] UploadRequest
- [ ] Multipart 上传的 Swift 封装
- [ ] 完整的 EventMonitor 集成到执行管线
- [ ] 更多 Alamofire 测试的适配与通过

---

## 已知差异列表

### 与 Alamofire 的行为差异

| 差异项 | 说明 | 影响 |
|---|---|---|
| 底层执行引擎 | AFNetworking 使用 `AFURLSessionManager`，Alamofire 使用自己的 `SessionDelegate` | 回调时序可能略有不同 |
| 参数编码 | AFNetworking 使用 `AFURLRequestSerialization`，Alamofire 使用 `ParameterEncoder` | 编码行为基本一致，但 API 形态不同 |
| 默认验证 | Alamofire 的 `validate()` 默认检查状态码和 Content-Type；AFNetworkingSwift 的 `validate()` 目前只检查状态码 | 后续版本对齐 |
| Multipart 上传 | Alamofire 有完整的 `MultipartFormData`；AFNetworkingSwift 暂未封装 | 后续版本补齐 |
| URLProtocol 支持 | Alamofire 支持自定义 URLProtocol 注册；AFNetworkingSwift 依赖 AFN 底层 | 不影响常规使用 |
| 请求重试管线 | Alamofire 的重试深度集成到请求生命周期；AFNetworkingSwift 目前在 completion 层面处理 | 增强版本深化集成 |

### 与现有 AFNetworking OC API 的兼容性

| 检查项 | 状态 |
|---|---|
| 现有 OC 公开 API 签名不变 | ✅ |
| 现有 OC 默认行为不变 | ✅ |
| 现有 OC 通知机制不变 | ✅ |
| 现有 CocoaPods 默认安装路径不变 | ✅ |
| 现有 SwiftPM `AFNetworking` product 不变 | ✅ |
| 现有安全策略默认值不变 | ✅ |
| 现有序列化器默认值不变 | ✅ |

---

## Break Change 风险清单

| 风险项 | 风险等级 | 缓解措施 |
|---|---|---|
| Package.swift platforms 提升到 iOS 13+ | 中 | 仅影响新增 target，原 AFNetworking target 保持 iOS 9+ |
| 新增 SwiftSupport 头文件 | 低 | 不导入到根聚合头 AFNetworking.h |
| 新增 subspec | 低 | 显式 opt-in，不影响默认安装 |
| 新增 SwiftPM target | 低 | 原 AFNetworking product/target 保持不变 |