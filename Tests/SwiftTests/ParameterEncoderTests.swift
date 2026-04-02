// ParameterEncoderTests.swift

import XCTest
@testable import AFNetworkingSwift

final class ParameterEncoderTests: XCTestCase {

    // MARK: - JSONParameterEncoder

    func testJSONParameterEncoderEncodesBody() throws {
        struct Login: Encodable { let username: String; let password: String }
        let encoder = JSONParameterEncoder.default
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"

        let encoded = try encoder.encode(Login(username: "user", password: "pass"), into: request)

        XCTAssertNotNil(encoded.httpBody)
        let json = try JSONSerialization.jsonObject(with: encoded.httpBody!) as! [String: Any]
        XCTAssertEqual(json["username"] as? String, "user")
        XCTAssertEqual(json["password"] as? String, "pass")
        XCTAssertEqual(encoded.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testJSONParameterEncoderNilParametersPassthrough() throws {
        let encoder = JSONParameterEncoder.default
        let request = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let encoded = try encoder.encode(nil as String?, into: request)
        XCTAssertNil(encoded.httpBody)
    }

    func testJSONParameterEncoderPreservesExistingContentType() throws {
        struct Payload: Encodable { let key: String }
        let encoder = JSONParameterEncoder.default
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let encoded = try encoder.encode(Payload(key: "value"), into: request)
        XCTAssertEqual(encoded.value(forHTTPHeaderField: "Content-Type"), "application/json; charset=utf-8")
    }

    func testJSONParameterEncoderCustomContentType() throws {
        struct Payload: Encodable { let key: String }
        let encoder = JSONParameterEncoder(contentType: "application/vnd.api+json")
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"

        let encoded = try encoder.encode(Payload(key: "value"), into: request)
        XCTAssertEqual(encoded.value(forHTTPHeaderField: "Content-Type"), "application/vnd.api+json")
    }

    // MARK: - URLEncodedFormParameterEncoder

    func testURLEncodedFormEncodesGETInQueryString() throws {
        struct Search: Encodable { let q: String; let page: Int }
        let encoder = URLEncodedFormParameterEncoder.default
        var request = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        request.httpMethod = "GET"

        let encoded = try encoder.encode(Search(q: "swift", page: 1), into: request)

        XCTAssertNil(encoded.httpBody)
        let url = encoded.url!.absoluteString
        XCTAssertTrue(url.contains("page=1"))
        XCTAssertTrue(url.contains("q=swift"))
    }

    func testURLEncodedFormEncodesPOSTInBody() throws {
        struct Login: Encodable { let username: String }
        let encoder = URLEncodedFormParameterEncoder.default
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"

        let encoded = try encoder.encode(Login(username: "user"), into: request)

        XCTAssertNotNil(encoded.httpBody)
        let body = String(data: encoded.httpBody!, encoding: .utf8)!
        XCTAssertTrue(body.contains("username=user"))
        XCTAssertEqual(encoded.value(forHTTPHeaderField: "Content-Type"),
                       "application/x-www-form-urlencoded; charset=utf-8")
    }

    func testURLEncodedFormForceQueryString() throws {
        struct Payload: Encodable { let key: String }
        let encoder = URLEncodedFormParameterEncoder(destination: .queryString)
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"

        let encoded = try encoder.encode(Payload(key: "value"), into: request)

        XCTAssertNil(encoded.httpBody)
        XCTAssertTrue(encoded.url!.absoluteString.contains("key=value"))
    }

    func testURLEncodedFormForceHTTPBody() throws {
        struct Payload: Encodable { let key: String }
        let encoder = URLEncodedFormParameterEncoder(destination: .httpBody)
        var request = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        request.httpMethod = "GET"

        let encoded = try encoder.encode(Payload(key: "value"), into: request)

        XCTAssertNotNil(encoded.httpBody)
        XCTAssertFalse(encoded.url!.absoluteString.contains("key=value"))
    }

    func testURLEncodedFormNilParametersPassthrough() throws {
        let encoder = URLEncodedFormParameterEncoder.default
        let request = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let encoded = try encoder.encode(nil as String?, into: request)
        XCTAssertEqual(encoded.url, request.url)
    }

    func testURLEncodedFormAppendsToExistingQuery() throws {
        struct Extra: Encodable { let extra: String }
        let encoder = URLEncodedFormParameterEncoder(destination: .queryString)
        var request = URLRequest(url: URL(string: "https://httpbin.org/get?existing=1")!)
        request.httpMethod = "GET"

        let encoded = try encoder.encode(Extra(extra: "2"), into: request)
        let url = encoded.url!.absoluteString
        XCTAssertTrue(url.contains("existing=1"))
        XCTAssertTrue(url.contains("extra=2"))
    }

    // MARK: - Convenience aliases

    func testJSONConvenienceAlias() {
        let encoder: any ParameterEncoder = .json
        XCTAssertTrue(encoder is JSONParameterEncoder)
    }

    func testURLEncodedFormConvenienceAlias() {
        let encoder: any ParameterEncoder = .urlEncodedForm
        XCTAssertTrue(encoder is URLEncodedFormParameterEncoder)
    }

    // MARK: - Session integration

    func testSessionRequestAcceptsEncodableParameters() {
        struct Params: Encodable { let q: String }
        let session = Session()
        let url = URL(string: "https://httpbin.org/get")!
        // Compile test — verifies the overload exists
        let request = session.request(url, parameters: Params(q: "test"), encoder: .urlEncodedForm)
        XCTAssertNotNil(request)
    }

    func testSessionRequestAcceptsJSONEncoder() {
        struct Body: Encodable { let name: String }
        let session = Session()
        let url = URL(string: "https://httpbin.org/post")!
        let request = session.request(url, method: .post, parameters: Body(name: "test"), encoder: .json)
        XCTAssertNotNil(request)
    }
}
