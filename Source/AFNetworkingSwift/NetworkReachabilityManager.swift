// NetworkReachabilityManager.swift
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

#if !os(watchOS)
import Foundation
#if SWIFT_PACKAGE
import AFNetworking
#endif

/// Swift wrapper over `AFNetworkReachabilityManager`, aligned with Alamofire's `NetworkReachabilityManager` API.
public final class NetworkReachabilityManager {

    // MARK: - NetworkReachabilityStatus

    /// 当前网络可达性状态
    public enum NetworkReachabilityStatus: Equatable {
        /// 状态未知
        case unknown
        /// 网络不可达
        case notReachable
        /// 网络可达，携带连接类型
        case reachable(ConnectionType)

        public static func == (lhs: NetworkReachabilityStatus, rhs: NetworkReachabilityStatus) -> Bool {
            switch (lhs, rhs) {
            case (.unknown, .unknown): return true
            case (.notReachable, .notReachable): return true
            case (.reachable(let a), .reachable(let b)): return a == b
            default: return false
            }
        }
    }

    /// 连接类型
    public enum ConnectionType {
        /// 以太网或 WiFi
        case ethernetOrWiFi
        /// 蜂窝网络（WWAN）
        case cellular
    }

    // MARK: - Properties

    /// 共享默认实例
    public static let `default` = NetworkReachabilityManager()

    /// 网络是否当前可达
    public var isReachable: Bool { manager.isReachable }

    /// 网络是否通过蜂窝（WWAN）可达
    public var isReachableOnCellular: Bool { manager.isReachableViaWWAN }

    /// 网络是否通过以太网或 WiFi 可达
    public var isReachableOnEthernetOrWiFi: Bool { manager.isReachableViaWiFi }

    /// 当前网络可达性状态
    public var status: NetworkReachabilityStatus {
        NetworkReachabilityStatus(manager.networkReachabilityStatus)
    }

    // MARK: - Private

    private let manager: AFNetworkReachabilityManager

    // MARK: - Initialization

    /// 使用默认 socket 地址初始化
    public init() {
        manager = AFNetworkReachabilityManager()
    }

    /// 使用指定域名初始化
    public init(domain: String) {
        manager = AFNetworkReachabilityManager(forDomain: domain)
    }

    // MARK: - Listening

    /// 开始监听网络可达性变化
    /// - Parameter listener: 状态变化时的回调闭包
    /// - Returns: 是否成功开始监听
    @discardableResult
    public func startListening(onUpdatePerforming listener: @escaping (NetworkReachabilityStatus) -> Void) -> Bool {
        manager.setReachabilityStatusChange { [weak self] _ in
            guard let self else { return }
            listener(self.status)
        }
        manager.startMonitoring()
        return true
    }

    /// 停止监听网络可达性变化
    public func stopListening() {
        manager.stopMonitoring()
        manager.setReachabilityStatusChange(nil)
    }
}

// MARK: - NetworkReachabilityStatus Conversion

private extension NetworkReachabilityManager.NetworkReachabilityStatus {
    init(_ objcStatus: AFNetworkReachabilityManager.Status) {
        switch objcStatus {
        case .notReachable:
            self = .notReachable
        case .reachableViaWWAN:
            self = .reachable(.cellular)
        case .reachableViaWiFi:
            self = .reachable(.ethernetOrWiFi)
        default:
            self = .unknown
        }
    }
}

#endif
