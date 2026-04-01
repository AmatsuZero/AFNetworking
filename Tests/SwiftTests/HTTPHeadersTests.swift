//
//  HTTPHeadersTests.swift
//
//  Copyright (c) 2014-2018 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#if SWIFT_PACKAGE
@testable import AFNetworkingSwift
import AFNetworking
#else
@testable import AFNetworking
#endif
import XCTest

// MARK: - API Compatibility Notes
//
// AFNetworkingSwift HTTPHeaders differs from Alamofire in the following ways:
//
// 1. init(_:) with [String:String] → AFNetworkingSwift uses labeled init(dictionary:)
//    Alamofire: HTTPHeaders(["key": ""])
//    AFNetworkingSwift: HTTPHeaders(dictionary: ["key": ""])
//
// 2. init(_:) with [HTTPHeader] → AFNetworkingSwift uses labeled init(headers:)
//    Alamofire: HTTPHeaders([HTTPHeader(...)])
//    AFNetworkingSwift: HTTPHeaders(headers: [HTTPHeader(...)])
//
// 3. update(HTTPHeader) / update(name:value:) → AFNetworkingSwift uses add(_:) / add(name:value:)
//    Alamofire: headers.update(name: "Key", value: "")
//    AFNetworkingSwift: headers.add(name: "Key", value: "")
//
// 4. subscript setter (headers["C"] = "c") → not available in AFNetworkingSwift
//    Tests using subscript setter are SKIPPED.
//
// 5. sorted() → not available in AFNetworkingSwift
//    Tests using sorted() are SKIPPED.

class HTTPHeadersTests: BaseTestCase {

    // MARK: - Adapted Tests

    func testHeadersAreStoreUniquelyByCaseInsensitiveName() {
        // Given
        // AFNetworkingSwift: dictionary literal init preserves insertion order but deduplicates
        let headersFromDictionaryLiteral: HTTPHeaders = ["key": "", "Key": "", "KEY": ""]
        // AFNetworkingSwift: labeled init(dictionary:) — note: sorts by key alphabetically
        let headersFromDictionary = HTTPHeaders(dictionary: ["key": "", "Key": "", "KEY": ""])
        // AFNetworkingSwift: labeled init(headers:)
        let headersFromArrayLiteral: HTTPHeaders = [HTTPHeader(name: "key", value: ""),
                                                    HTTPHeader(name: "Key", value: ""),
                                                    HTTPHeader(name: "KEY", value: "")]
        let headersFromArray = HTTPHeaders(headers: [HTTPHeader(name: "key", value: ""),
                                                     HTTPHeader(name: "Key", value: ""),
                                                     HTTPHeader(name: "KEY", value: "")])
        var headersCreatedManually = HTTPHeaders()
        headersCreatedManually.add(HTTPHeader(name: "key", value: ""))
        headersCreatedManually.add(name: "Key", value: "")
        headersCreatedManually.add(name: "KEY", value: "")

        // When, Then
        XCTAssertEqual(headersFromDictionaryLiteral.count, 1)
        XCTAssertEqual(headersFromDictionary.count, 1)
        XCTAssertEqual(headersFromArrayLiteral.count, 1)
        XCTAssertEqual(headersFromArray.count, 1)
        XCTAssertEqual(headersCreatedManually.count, 1)
    }

    func testHeadersPreserveOrderOfInsertion() {
        // Given
        let headersFromDictionaryLiteral: HTTPHeaders = ["c": "", "a": "", "b": ""]
        // Dictionary initializer can't preserve order.
        let headersFromArrayLiteral: HTTPHeaders = [HTTPHeader(name: "b", value: ""),
                                                    HTTPHeader(name: "a", value: ""),
                                                    HTTPHeader(name: "c", value: "")]
        let headersFromArray = HTTPHeaders(headers: [HTTPHeader(name: "b", value: ""),
                                                     HTTPHeader(name: "a", value: ""),
                                                     HTTPHeader(name: "c", value: "")])
        var headersCreatedManually = HTTPHeaders()
        headersCreatedManually.add(HTTPHeader(name: "c", value: ""))
        headersCreatedManually.add(name: "b", value: "")
        headersCreatedManually.add(name: "a", value: "")

        // When
        let dictionaryLiteralNames = headersFromDictionaryLiteral.map(\.name)
        let arrayLiteralNames = headersFromArrayLiteral.map(\.name)
        let arrayNames = headersFromArray.map(\.name)
        let manualNames = headersCreatedManually.map(\.name)

        // Then
        XCTAssertEqual(dictionaryLiteralNames, ["c", "a", "b"])
        XCTAssertEqual(arrayLiteralNames, ["b", "a", "c"])
        XCTAssertEqual(arrayNames, ["b", "a", "c"])
        XCTAssertEqual(manualNames, ["c", "b", "a"])
    }

    // MARK: - Skipped Tests (missing API in AFNetworkingSwift)

    // testHeadersCanBeProperlySortedByName — SKIPPED: HTTPHeaders.sorted() not available
    // testHeadersCanInsensitivelyGetAndSetThroughSubscript — SKIPPED: subscript setter not available
    // testHeadersPreserveLastFormAndValueOfAName — SKIPPED: subscript setter not available

    func testHeadersHaveUnsortedDescription() {
        // Given
        let headers: HTTPHeaders = ["c": "c", "a": "a", "b": "b"]

        // When
        let description = headers.description
        let expectedDescription = """
        c: c
        a: a
        b: b
        """

        // Then
        XCTAssertEqual(description, expectedDescription)
    }
}
