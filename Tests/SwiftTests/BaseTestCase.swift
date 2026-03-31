// BaseTestCase.swift
// 测试基类，提供 Alamofire 测试所需的公共基础设施。
// 对齐 Alamofire Tests 中的 BaseTestCase。

import XCTest
#if SWIFT_PACKAGE
@testable import AFNetworkingSwift
import AFNetworking
#else
@testable import AFNetworking
#endif

/// 测试基类
@MainActor
class BaseTestCase: XCTestCase {

    /// 默认超时时间
    let timeout: TimeInterval = 30.0

    /// 测试用 Session
    var session: Session!

    override func setUp() async throws {
        try await super.setUp()
        session = Session()
    }

    override func tearDown() async throws {
        session = nil
        try await super.tearDown()
    }

    // MARK: - 辅助方法

    /// httpbin 基础 URL
    var urlString: String {
        "https://httpbin.org"
    }

    /// 创建期望并等待
    func expectation(description: String, execute: @escaping (@escaping () -> Void) -> Void) {
        let exp = expectation(description: description)
        execute {
            exp.fulfill()
        }
        waitForExpectations(timeout: timeout)
    }
}