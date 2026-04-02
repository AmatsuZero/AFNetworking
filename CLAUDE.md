# AFNetworking 项目开发规则

## Swift 扩展开发原则

> 来源：2026-04-02 复盘（提交范围 42e7e087..6f16f11）
> 背景：Swift 扩展目标是提供与 Alamofire 接口对齐的包装层，让 OC 和 Swift 用户都能受益。

---

### Rule 1：OC 优先原则（核心规则）

**任何新功能，必须先在 OC 层（`AFNetworking/` 目录）实现，Swift 层只做薄包装。**

提交新功能前的检查清单：
- [ ] OC 用户是否有合理的使用场景？
- [ ] 是否在 `AFHTTPSessionManager` 或相关 OC 类上扩展了 category/方法？
- [ ] Swift 层的实现是否只是调用 OC 层，而非独立实现逻辑？

---

### Rule 2：Swift-only 功能的合法性判断

**允许**纯 Swift 实现（无需 OC 对应）的情况：
- 功能依赖 Swift 语言特性：`async/await`、`Actor`、`Combine`、泛型关联类型、枚举关联值
- 功能是语法糖/便利 API，底层调用 OC 实现
- 并发安全封装（Swift Concurrency 模型）

**禁止**纯 Swift 实现的情况：
- 业务逻辑功能（HTTP 头管理、请求拦截、响应验证、缓存控制等）
- 直接从 Alamofire 复制实现，跳过 OC 层

---

### Rule 3：参照 Alamofire 的正确姿势

- ✅ **API 形状对齐**：方法签名、参数名、返回类型与 Alamofire 保持一致
- ❌ **禁止照搬实现**：不能直接从 Alamofire 复制 Swift 实现逻辑

---

### Rule 4：新功能提交前的架构自检

```
1. 这是纯语言特性功能吗？（async/await / Combine / 泛型关联类型）
   → 是：可以纯 Swift 实现
   → 否：继续 ↓

2. AFNetworking OC 层已有能力支撑点吗？
   → 有：在 OC 层扩展，Swift 只做包装
   → 没有：先在 OC 层新增实现，再 Swift 包装

3. OC 用户能通过 AFHTTPSessionManager / AF* 直接使用这个功能吗？
   → 不能：回到步骤 2
   → 能：可以提交
```

---

### Rule 5：已偏离实现的修复优先级

目前以下功能**仅存在于 Swift 层**，需要分批补齐 OC 实现：

| 优先级 | 功能 | Swift 文件 |
|-------|------|-----------|
| P1 | HTTP 头部管理 | `Core/HTTPHeaders.swift` |
| P1 | 响应验证 | `Validation/ResponseValidator.swift` |
| P2 | 请求拦截器 | `Interceptor/RequestInterceptor.swift` |
| P2 | 信任评估器扩展 | `Security/ServerTrustManager.swift` |
| P3 | 缓存/重定向控制 | `CachedResponseHandler.swift`, `RedirectHandler.swift` |
| P3 | 请求上下文/描述符 | `Request/RequestContext.swift`, `Request/RequestDescriptor.swift` |

---

### Rule 6：验收标准

每次 Swift 扩展 PR 必须满足：
1. 新功能在 OC 层有对应实现，或有明确的"Swift-only 合理性"注释
2. 同时提供 ObjcTests 和 SwiftTests
3. 不存在"只有 Swift 实现、OC 层完全无对应"的业务逻辑功能
