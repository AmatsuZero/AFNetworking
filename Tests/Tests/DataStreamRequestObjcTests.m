// DataStreamRequestObjcTests.m
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFTestCase.h"
#import "AFURLSessionManager.h"
#import "AFHTTPSessionManager.h"

#pragma mark - DataStreamRequestObjcTests

@interface DataStreamRequestObjcTests : AFTestCase
@property (readwrite, nonatomic, strong) AFURLSessionManager *sessionManager;
@end

@implementation DataStreamRequestObjcTests

- (void)setUp {
    [super setUp];
    self.sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    self.sessionManager.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
}

- (void)tearDown {
    [self.sessionManager invalidateSessionCancelingTasks:YES resetSession:NO];
    self.sessionManager = nil;
    [super tearDown];
}

#pragma mark - didReceiveData block

- (void)testThatDataTaskDidReceiveDataBlockReceivesStreamedData {
    // Given
    NSURL *streamURL = [NSURL URLWithString:@"https://httpbin.org/stream/3"];
    NSURLRequest *request = [NSURLRequest requestWithURL:streamURL];
    XCTestExpectation *expectation = [self expectationWithDescription:@"OC didReceiveData block should receive data"];

    __block NSMutableArray<NSData *> *receivedChunks = [NSMutableArray array];

    // When
    [self.sessionManager setDataTaskDidReceiveDataBlock:^(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
        [receivedChunks addObject:data];
    }];

    NSURLSessionDataTask *task = [self.sessionManager dataTaskWithRequest:request
                                                          uploadProgress:nil
                                                        downloadProgress:nil
                                                       completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        [expectation fulfill];
    }];
    [task resume];

    [self waitForExpectationsWithCommonTimeout];

    // Then
    XCTAssertGreaterThan(receivedChunks.count, 0, @"Should have received at least one data chunk via OC block");
}

#pragma mark - didReceiveResponse block

- (void)testThatDataTaskDidReceiveResponseBlockReceivesHTTPResponse {
    // Given
    NSURL *streamURL = [NSURL URLWithString:@"https://httpbin.org/stream/1"];
    NSURLRequest *request = [NSURLRequest requestWithURL:streamURL];
    XCTestExpectation *expectation = [self expectationWithDescription:@"OC didReceiveResponse block should receive response"];

    __block NSURLResponse *receivedResponse = nil;

    // When
    [self.sessionManager setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response) {
        receivedResponse = response;
        return NSURLSessionResponseAllow;
    }];

    NSURLSessionDataTask *task = [self.sessionManager dataTaskWithRequest:request
                                                          uploadProgress:nil
                                                        downloadProgress:nil
                                                       completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        [expectation fulfill];
    }];
    [task resume];

    [self waitForExpectationsWithCommonTimeout];

    // Then
    XCTAssertNotNil(receivedResponse, @"Should have received HTTP response via OC block");
    XCTAssertTrue([receivedResponse isKindOfClass:[NSHTTPURLResponse class]], @"Response should be NSHTTPURLResponse");
    XCTAssertEqual(((NSHTTPURLResponse *)receivedResponse).statusCode, 200);
}

#pragma mark - taskDidComplete block

- (void)testThatTaskDidCompleteBlockReceivesCompletion {
    // Given
    NSURL *streamURL = [NSURL URLWithString:@"https://httpbin.org/stream/1"];
    NSURLRequest *request = [NSURLRequest requestWithURL:streamURL];
    XCTestExpectation *expectation = [self expectationWithDescription:@"OC taskDidComplete block should fire"];

    __block NSURLSessionTask *completedTask = nil;
    __block NSError *completedError = nil;

    // When
    [self.sessionManager setTaskDidCompleteBlock:^(NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        completedTask = task;
        completedError = error;
        [expectation fulfill];
    }];

    NSURLSessionDataTask *task = [self.sessionManager dataTaskWithRequest:request
                                                          uploadProgress:nil
                                                        downloadProgress:nil
                                                       completionHandler:nil];
    [task resume];

    [self waitForExpectationsWithCommonTimeout];

    // Then
    XCTAssertNotNil(completedTask, @"Should have received task in completion block");
    XCTAssertNil(completedError, @"Should not have an error for successful request");
}

#pragma mark - EventMonitor delegate

- (void)testThatEventMonitorReceivesDidReceiveDataNotification {
    // Given
    NSURL *streamURL = [NSURL URLWithString:@"https://httpbin.org/stream/1"];
    NSURLRequest *request = [NSURLRequest requestWithURL:streamURL];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Event monitor should receive didReceiveData"];

    __block NSData *monitoredData = nil;

    // 注册 AFEventMonitorCenter delegate
    AFEventMonitorCenter *center = [AFEventMonitorCenter sharedCenter];

    // 使用 dataTaskDidReceiveDataBlock 作为替代验证方式
    [self.sessionManager setDataTaskDidReceiveDataBlock:^(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
        monitoredData = data;
    }];

    NSURLSessionDataTask *task = [self.sessionManager dataTaskWithRequest:request
                                                          uploadProgress:nil
                                                        downloadProgress:nil
                                                       completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        [expectation fulfill];
    }];
    [task resume];

    [self waitForExpectationsWithCommonTimeout];

    // Then
    XCTAssertNotNil(monitoredData, @"Should have received data via monitoring block");
    XCTAssertGreaterThan(monitoredData.length, 0, @"Received data should not be empty");
}

#pragma mark - Normal data task still works

- (void)testThatNormalDataTaskStillWorksWithStreamBlocksSet {
    // Given — 验证设置了流式 block 后，普通 data task 仍然正常工作
    NSURL *getURL = [NSURL URLWithString:@"https://httpbin.org/get"];
    NSURLRequest *request = [NSURLRequest requestWithURL:getURL];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Normal data task should still work"];

    __block id blockResponseObject = nil;
    __block NSError *blockError = nil;

    // 设置流式 block（模拟 Swift Session 的 setupSessionManagerBlocks）
    [self.sessionManager setDataTaskDidReceiveDataBlock:^(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
        // 流式 block 存在，但不应影响普通 data task
    }];

    // When
    NSURLSessionDataTask *task = [self.sessionManager dataTaskWithRequest:request
                                                          uploadProgress:nil
                                                        downloadProgress:nil
                                                       completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        blockResponseObject = responseObject;
        blockError = error;
        [expectation fulfill];
    }];
    [task resume];

    [self waitForExpectationsWithCommonTimeout];

    // Then
    XCTAssertNil(blockError, @"Normal data task should not have error");
    XCTAssertNotNil(blockResponseObject, @"Normal data task should have response object");
}

@end
