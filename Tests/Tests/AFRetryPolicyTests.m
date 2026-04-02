// AFRetryPolicyTests.m

#import <XCTest/XCTest.h>
#import "AFRetryPolicy.h"

@interface AFRetryPolicyTests : XCTestCase
@end

@implementation AFRetryPolicyTests

#pragma mark - Default Policy

- (void)testDefaultPolicyProperties {
    AFRetryPolicy *policy = [AFRetryPolicy defaultPolicy];
    XCTAssertEqual(policy.retryLimit, 2);
    XCTAssertEqualWithAccuracy(policy.exponentialBackoffBase, 2.0, 0.01);
    XCTAssertEqualWithAccuracy(policy.exponentialBackoffScale, 0.5, 0.01);
    XCTAssertTrue([policy.retryableHTTPMethods containsObject:@"GET"]);
    XCTAssertTrue([policy.retryableHTTPMethods containsObject:@"PUT"]);
    XCTAssertFalse([policy.retryableHTTPMethods containsObject:@"POST"]);
}

#pragma mark - Retry Delay

- (void)testRetryDelayCalculation {
    AFRetryPolicy *policy = [AFRetryPolicy defaultPolicy];
    // delay = pow(2, retryCount) * 0.5
    XCTAssertEqualWithAccuracy([policy retryDelayForRetryCount:0], 0.5, 0.01);  // 2^0 * 0.5
    XCTAssertEqualWithAccuracy([policy retryDelayForRetryCount:1], 1.0, 0.01);  // 2^1 * 0.5
    XCTAssertEqualWithAccuracy([policy retryDelayForRetryCount:2], 2.0, 0.01);  // 2^2 * 0.5
    XCTAssertEqualWithAccuracy([policy retryDelayForRetryCount:3], 4.0, 0.01);  // 2^3 * 0.5
}

#pragma mark - Should Retry

- (void)testShouldRetryOnTimeout {
    AFRetryPolicy *policy = [AFRetryPolicy defaultPolicy];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbin.org/get"]];
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
    XCTAssertTrue([policy shouldRetryRequest:request response:nil withError:error]);
}

- (void)testShouldNotRetryOnBadURL {
    AFRetryPolicy *policy = [AFRetryPolicy defaultPolicy];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbin.org/get"]];
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
    XCTAssertFalse([policy shouldRetryRequest:request response:nil withError:error]);
}

- (void)testShouldNotRetryPOST {
    AFRetryPolicy *policy = [AFRetryPolicy defaultPolicy];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbin.org/post"]];
    request.HTTPMethod = @"POST";
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
    XCTAssertFalse([policy shouldRetryRequest:request response:nil withError:error]);
}

- (void)testShouldRetryOnRetryableStatusCode {
    AFRetryPolicy *policy = [AFRetryPolicy defaultPolicy];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbin.org/get"]];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                              statusCode:503
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:nil];
    NSError *error = [NSError errorWithDomain:@"HTTP" code:503 userInfo:nil];
    XCTAssertTrue([policy shouldRetryRequest:request response:response withError:error]);
}

#pragma mark - AFRequestRetrier Protocol

- (void)testRetrierProtocolRetries {
    AFRetryPolicy *policy = [AFRetryPolicy defaultPolicy];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbin.org/get"]];
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];

    XCTestExpectation *expectation = [self expectationWithDescription:@"retrier callback"];
    [policy shouldRetryRequest:request withError:error retryCount:0 completion:^(AFRetryResult *result) {
        XCTAssertEqual(result.type, AFRetryResultTypeRetryWithDelay);
        XCTAssertEqualWithAccuracy(result.delay, 0.5, 0.01);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRetrierProtocolDoNotRetryWhenLimitExceeded {
    AFRetryPolicy *policy = [AFRetryPolicy defaultPolicy];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbin.org/get"]];
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];

    XCTestExpectation *expectation = [self expectationWithDescription:@"no retry"];
    [policy shouldRetryRequest:request withError:error retryCount:2 completion:^(AFRetryResult *result) {
        XCTAssertEqual(result.type, AFRetryResultTypeDoNotRetry);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - ConnectionLostRetryPolicy

- (void)testConnectionLostPolicyRetriesOnConnectionLost {
    AFConnectionLostRetryPolicy *policy = [AFConnectionLostRetryPolicy defaultPolicy];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbin.org/get"]];
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNetworkConnectionLost userInfo:nil];
    XCTAssertTrue([policy shouldRetryRequest:request response:nil withError:error]);
}

- (void)testConnectionLostPolicyDoNotRetryOnTimeout {
    AFConnectionLostRetryPolicy *policy = [AFConnectionLostRetryPolicy defaultPolicy];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbin.org/get"]];
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
    XCTAssertFalse([policy shouldRetryRequest:request response:nil withError:error]);
}

#pragma mark - Custom Configuration

- (void)testCustomPolicyConfiguration {
    NSMutableIndexSet *statusCodes = [NSMutableIndexSet indexSet];
    [statusCodes addIndex:429]; // Too Many Requests

    AFRetryPolicy *policy = [[AFRetryPolicy alloc]
        initWithRetryLimit:5
        exponentialBackoffBase:3.0
        exponentialBackoffScale:1.0
        retryableHTTPMethods:[NSSet setWithArray:@[@"GET", @"POST"]]
        retryableHTTPStatusCodes:statusCodes
        retryableURLErrorCodes:[NSSet setWithArray:@[@(NSURLErrorTimedOut)]]];

    XCTAssertEqual(policy.retryLimit, 5);
    XCTAssertEqualWithAccuracy(policy.exponentialBackoffBase, 3.0, 0.01);
    XCTAssertTrue([policy.retryableHTTPMethods containsObject:@"POST"]);

    // delay = pow(3, 0) * 1.0 = 1.0
    XCTAssertEqualWithAccuracy([policy retryDelayForRetryCount:0], 1.0, 0.01);
    // delay = pow(3, 1) * 1.0 = 3.0
    XCTAssertEqualWithAccuracy([policy retryDelayForRetryCount:1], 3.0, 0.01);
}

@end
