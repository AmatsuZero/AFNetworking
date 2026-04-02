// CompatibilityTests.swift
// 兼容性回归测试，确保引入 Swift 包装器后不破坏现有 Objective-C API 的默认行为。

import XCTest
#if SWIFT_PACKAGE
import AFNetworking
@testable import AFNetworkingSwift
#else
import AFNetworking
#endif

/// 兼容性回归测试
/// 验证现有 Objective-C API 在引入 SwiftSupport 层后行为不变。
@MainActor
final class CompatibilityTests: XCTestCase {

    let timeout: TimeInterval = 30.0

    // MARK: - AFHTTPSessionManager 默认行为不变

    func testDefaultManagerCreation() {
        let manager = AFHTTPSessionManager()
        XCTAssertNotNil(manager)
        XCTAssertNotNil(manager.requestSerializer)
        XCTAssertNotNil(manager.responseSerializer)
        XCTAssertNotNil(manager.securityPolicy)
    }

    func testDefaultSecurityPolicy() {
        let policy = AFSecurityPolicy.default()
        XCTAssertEqual(policy.sslPinningMode, .none)
        XCTAssertFalse(policy.allowInvalidCertificates)
        XCTAssertTrue(policy.validatesDomainName)
    }

    func testDefaultRequestSerializer() {
        let serializer = AFHTTPRequestSerializer()
        XCTAssertNotNil(serializer)
    }

    func testDefaultResponseSerializer() {
        let serializer = AFJSONResponseSerializer()
        XCTAssertNotNil(serializer)
        XCTAssertNotNil(serializer.acceptableStatusCodes)
        XCTAssertNotNil(serializer.acceptableContentTypes)
    }

    // MARK: - 旧式 GET/POST API 仍然可用

    func testLegacyGETRequest() {
        let exp = expectation(description: "Legacy GET should work")
        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFHTTPResponseSerializer()

        manager.get("https://httpbin.org/get", parameters: nil, headers: nil, progress: nil,
                     success: { _, response in
            XCTAssertNotNil(response)
            exp.fulfill()
        }, failure: { _, error in
            XCTFail("Legacy GET failed: \(error)")
            exp.fulfill()
        })

        waitForExpectations(timeout: timeout)
    }

    func testLegacyPOSTRequest() {
        let exp = expectation(description: "Legacy POST should work")
        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFHTTPResponseSerializer()

        manager.post("https://httpbin.org/post", parameters: ["key": "value"], headers: nil, progress: nil,
                      success: { _, response in
            XCTAssertNotNil(response)
            exp.fulfill()
        }, failure: { _, error in
            XCTFail("Legacy POST failed: \(error)")
            exp.fulfill()
        })

        waitForExpectations(timeout: timeout)
    }

    // MARK: - 旧式通知仍然发出

    func testTaskDidCompleteNotification() {
        let exp = expectation(description: "Task complete notification should fire")
        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFHTTPResponseSerializer()

        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.AFNetworkingTaskDidComplete,
            object: nil,
            queue: nil
        ) { _ in
            exp.fulfill()
        }

        manager.get("https://httpbin.org/get", parameters: nil, headers: nil, progress: nil,
                     success: { _, _ in }, failure: { _, _ in })

        waitForExpectations(timeout: timeout)
        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Swift 类型验证

    func testSwiftTypesExist() {
        // 验证新增 Swift 类型可以正常创建
        let method: HTTPMethod = .get
        XCTAssertEqual(method.rawValue, "GET")

        let header = HTTPHeader(name: "Accept", value: "application/json")
        XCTAssertEqual(header.name, "Accept")

        var headers = HTTPHeaders()
        headers.add(header)
        XCTAssertEqual(headers.count, 1)

        let descriptor = RequestDescriptor(
            urlString: "https://httpbin.org/get",
            method: .get,
            parameters: nil,
            encoding: .auto,
            headers: nil
        )
        XCTAssertEqual(descriptor.urlString, "https://httpbin.org/get")

        let context = RequestContext(descriptor: descriptor)
        XCTAssertEqual(context.state, .initialized)
        XCTAssertNotNil(context.identifier)
    }
}
