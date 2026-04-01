//
//  AFError+Tests.swift
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
import Foundation

// MARK: - API Compatibility Notes
//
// Alamofire's AFError uses richly nested reason enums:
//   AFError.ParameterEncodingFailureReason
//   AFError.MultipartEncodingFailureReason
//   AFError.ResponseSerializationFailureReason
//   AFError.ResponseValidationFailureReason
//   AFError.ServerTrustFailureReason
//   AFError.URLRequestValidationFailureReason
//
// AFNetworkingSwift's AFError is a flat enum with string-based reason payloads.
// None of the nested reason sub-enums exist, so the Alamofire helper properties
// that pattern-match against them cannot be adapted directly.
//
// Adapted subset: only the cases that exist in AFNetworkingSwift's flat AFError
// and do not depend on nested reason types.

extension AFError {

    // MARK: - Flat case helpers (fully adapted)

    var isExplicitlyCancelled: Bool {
        if case .explicitlyCancelled = self { return true }
        return false
    }

    var isSessionDeinitialized: Bool {
        if case .sessionDeinitialized = self { return true }
        return false
    }

    var isInvalidURL: Bool {
        if case .invalidURL = self { return true }
        return false
    }

    var isCreateURLRequestFailed: Bool {
        if case .createURLRequestFailed = self { return true }
        return false
    }

    var isRequestAdaptationFailed: Bool {
        if case .requestAdaptationFailed = self { return true }
        return false
    }

    var isRequestRetryFailed: Bool {
        if case .requestRetryFailed = self { return true }
        return false
    }

    // MARK: - String-reason helpers (partially adapted)
    //
    // AFNetworkingSwift uses String payloads for these cases.
    // The original per-reason Bool properties are collapsed into single
    // case-match helpers; callers must inspect the reason string directly
    // for fine-grained discrimination.

    var isResponseValidationFailed: Bool {
        if case .responseValidationFailed = self { return true }
        return false
    }

    var isResponseSerializationFailed: Bool {
        if case .responseSerializationFailed = self { return true }
        return false
    }

    var isServerTrustEvaluationFailed: Bool {
        if case .serverTrustEvaluationFailed = self { return true }
        return false
    }

    // MARK: - Network connectivity helper (unchanged from Alamofire)

    var isHostURLError: Bool {
        guard let errorCode = (underlyingError as? URLError)?.code else { return false }
        return [.cannotConnectToHost, .cannotFindHost].contains(errorCode)
    }

    // MARK: - Underlying error accessor

    /// Returns the underlying Error for cases that carry one.
    var underlyingError: Error? {
        switch self {
        case .createURLRequestFailed(let error):
            return error
        case .requestAdaptationFailed(let error):
            return error
        case .requestRetryFailed(let retryError, _):
            return retryError
        default:
            return nil
        }
    }

    // MARK: - Skipped helpers (require nested reason enums absent in AFNetworkingSwift)
    //
    // The following properties from AFError+AlamofireTests.swift are NOT adapted
    // because they depend on AFError sub-enums that do not exist in AFNetworkingSwift:
    //
    //   isMissingURLFailed             — requires ParameterEncodingFailureReason.missingURL
    //   isJSONEncodingFailed           — requires ParameterEncodingFailureReason.jsonEncodingFailed
    //   isBodyPartURLInvalid           — requires MultipartEncodingFailureReason
    //   isBodyPartFilenameInvalid      — requires MultipartEncodingFailureReason
    //   isBodyPartFileNotReachable     — requires MultipartEncodingFailureReason
    //   isBodyPartFileNotReachableWithError — requires MultipartEncodingFailureReason
    //   isBodyPartFileIsDirectory      — requires MultipartEncodingFailureReason
    //   isBodyPartFileSizeNotAvailable — requires MultipartEncodingFailureReason
    //   isBodyPartFileSizeQueryFailedWithError — requires MultipartEncodingFailureReason
    //   isBodyPartInputStreamCreationFailed    — requires MultipartEncodingFailureReason
    //   isOutputStreamCreationFailed   — requires MultipartEncodingFailureReason
    //   isOutputStreamFileAlreadyExists — requires MultipartEncodingFailureReason
    //   isOutputStreamURLInvalid       — requires MultipartEncodingFailureReason
    //   isOutputStreamWriteFailed      — requires MultipartEncodingFailureReason
    //   isInputStreamReadFailed        — requires MultipartEncodingFailureReason
    //   isInputDataNilOrZeroLength     — requires ResponseSerializationFailureReason
    //   isInputFileNil                 — requires ResponseSerializationFailureReason
    //   isInputFileReadFailed          — requires ResponseSerializationFailureReason
    //   isStringSerializationFailed    — requires ResponseSerializationFailureReason
    //   isJSONSerializationFailed      — requires ResponseSerializationFailureReason
    //   isJSONDecodingFailed           — requires ResponseSerializationFailureReason
    //   isInvalidEmptyResponse         — requires ResponseSerializationFailureReason
    //   isDataFileNil                  — requires ResponseValidationFailureReason
    //   isDataFileReadFailed           — requires ResponseValidationFailureReason
    //   isMissingContentType           — requires ResponseValidationFailureReason
    //   isUnacceptableContentType      — requires ResponseValidationFailureReason
    //   isUnacceptableStatusCode       — requires ResponseValidationFailureReason
    //   isBodyDataInGETRequest         — requires URLRequestValidationFailureReason
    //   ServerTrustFailureReason block — requires ServerTrustFailureReason sub-enum
}
