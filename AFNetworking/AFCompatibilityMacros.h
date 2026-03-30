// AFCompatibilityMacros.h
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

#ifndef AFCompatibilityMacros_h
#define AFCompatibilityMacros_h

#ifdef API_AVAILABLE
    #define AF_API_AVAILABLE(...) API_AVAILABLE(__VA_ARGS__)
#else
    #define AF_API_AVAILABLE(...)
#endif // API_AVAILABLE

#ifdef API_UNAVAILABLE
    #define AF_API_UNAVAILABLE(...) API_UNAVAILABLE(__VA_ARGS__)
#else
    #define AF_API_UNAVAILABLE(...)
#endif // API_UNAVAILABLE

#if __has_warning("-Wunguarded-availability-new")
    #define AF_CAN_USE_AT_AVAILABLE 1
#else
    #define AF_CAN_USE_AT_AVAILABLE 0
#endif

#if ((__IPHONE_OS_VERSION_MAX_ALLOWED && __IPHONE_OS_VERSION_MAX_ALLOWED < 100000) || (__MAC_OS_VERSION_MAX_ALLOWED && __MAC_OS_VERSION_MAX_ALLOWED < 101200) ||(__WATCH_OS_MAX_VERSION_ALLOWED && __WATCH_OS_MAX_VERSION_ALLOWED < 30000) ||(__TV_OS_MAX_VERSION_ALLOWED && __TV_OS_MAX_VERSION_ALLOWED < 100000))
    #define AF_CAN_INCLUDE_SESSION_TASK_METRICS 0
#else
    #define AF_CAN_INCLUDE_SESSION_TASK_METRICS 1
#endif

// MARK: - Swift 现代化兼容性宏

// NS_SWIFT_SENDABLE: 标记类型为 Swift Sendable，用于并发安全
// 需要 Xcode 14+ / Swift 5.7+ / clang 属性 swift_attr 支持
#ifndef AF_SWIFT_SENDABLE
    #if defined(__has_attribute) && __has_attribute(swift_attr)
        #define AF_SWIFT_SENDABLE __attribute__((swift_attr("@Sendable")))
    #else
        #define AF_SWIFT_SENDABLE
    #endif
#endif

// NS_SWIFT_ASYNC_NAME: 为方法提供 Swift async/await 版本
// 需要 SDK 中定义了 NS_SWIFT_ASYNC_NAME 宏（Xcode 13+ / Swift 5.5+）
#ifndef AF_SWIFT_ASYNC_NAME
    #if defined(NS_SWIFT_ASYNC_NAME)
        #define AF_SWIFT_ASYNC_NAME(...) NS_SWIFT_ASYNC_NAME(__VA_ARGS__)
    #else
        #define AF_SWIFT_ASYNC_NAME(...)
    #endif
#endif

// NS_SWIFT_ASYNC: 指定 completion handler 参数索引以生成 async 版本
#ifndef AF_SWIFT_ASYNC
    #if defined(NS_SWIFT_ASYNC)
        #define AF_SWIFT_ASYNC(...) NS_SWIFT_ASYNC(__VA_ARGS__)
    #else
        #define AF_SWIFT_ASYNC(...)
    #endif
#endif

// NS_SWIFT_DISABLE_ASYNC: 禁止自动生成 async 版本
#ifndef AF_SWIFT_DISABLE_ASYNC
    #if defined(NS_SWIFT_DISABLE_ASYNC)
        #define AF_SWIFT_DISABLE_ASYNC NS_SWIFT_DISABLE_ASYNC
    #else
        #define AF_SWIFT_DISABLE_ASYNC
    #endif
#endif

#endif /* AFCompatibilityMacros_h */
