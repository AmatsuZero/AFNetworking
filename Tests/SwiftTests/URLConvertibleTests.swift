// URLConvertibleTests.swift

import XCTest
@testable import AFNetworkingSwift

final class URLConvertibleTests: XCTestCase {

    // MARK: - String: URLConvertible

    func testStringAsURLValid() throws {
        let urlString = "https://httpbin.org/get"
        let url = try urlString.asURL()
        XCTAssertEqual(url.absoluteString, urlString)
    }

    func testStringAsURLInvalid() {
        let invalid = ""
        XCTAssertThrowsError(try invalid.asURL()) { error in
            guard case AFError.invalidURL = error else {
                XCTFail("Expected AFError.invalidURL, got \(error)")
                return
            }
        }
    }

    // MARK: - URL: URLConvertible

    func testURLAsURL() throws {
        let original = URL(string: "https://httpbin.org/post")!
        let result = try original.asURL()
        XCTAssertEqual(result, original)
    }

    // MARK: - URLComponents: URLConvertible

    func testURLComponentsAsURLValid() throws {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "httpbin.org"
        components.path = "/get"
        components.queryItems = [URLQueryItem(name: "key", value: "value")]

        let url = try components.asURL()
        XCTAssertEqual(url.host, "httpbin.org")
        XCTAssertEqual(url.path, "/get")
        XCTAssertTrue(url.absoluteString.contains("key=value"))
    }

    func testURLComponentsAsURLInvalid() {
        // URLComponents with a nil url (path-only, no scheme/host)
        var components = URLComponents()
        components.host = ""
        components.path = "not a valid path with spaces"
        // If URLComponents produces nil url, we expect an error
        if components.url == nil {
            XCTAssertThrowsError(try components.asURL())
        }
    }

    // MARK: - URLRequestConvertible

    func testURLRequestAsURLRequest() throws {
        let original = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let result = try original.asURLRequest()
        XCTAssertEqual(result.url, original.url)
    }

    // MARK: - Session URLConvertible overloads

    func testSessionRequestAcceptsURL() {
        let session = Session()
        let url = URL(string: "https://httpbin.org/get")!
        // Should compile — this is the key type-safety test
        let request = session.request(url)
        XCTAssertNotNil(request)
    }

    func testSessionRequestAcceptsURLComponents() {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "httpbin.org"
        components.path = "/get"

        let session = Session()
        let request = session.request(components)
        XCTAssertNotNil(request)
    }

    func testSessionDownloadAcceptsURL() {
        let session = Session()
        let url = URL(string: "https://httpbin.org/bytes/1024")!
        let request = session.download(url)
        XCTAssertNotNil(request)
    }

    func testSessionUploadDataAcceptsURL() {
        let session = Session()
        let url = URL(string: "https://httpbin.org/post")!
        let request = session.upload(Data(), to: url)
        XCTAssertNotNil(request)
    }
}
