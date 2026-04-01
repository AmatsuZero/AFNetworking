// swift-tools-version:5.3
//
//  Package.swift
//
//  Copyright (c) 2020 Alamofire Software Foundation (http://alamofire.org/)
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

import PackageDescription

let package = Package(name: "AFNetworking",
                      platforms: [.macOS(.v10_15),
                                  .iOS(.v13),
                                  .tvOS(.v13),
                                  .watchOS(.v6)],
                      products: [.library(name: "AFNetworking",
                                          targets: ["AFNetworking"]),
                                 .library(name: "AFNetworkingSwift",
                                          targets: ["AFNetworkingSwift"])],
                      targets: [.target(name: "AFNetworking",
                                        path: "AFNetworking",
                                        publicHeadersPath: ""),
                                .target(name: "AFNetworkingSwift",
                                        dependencies: ["AFNetworking"],
                                        path: "Source/AFNetworkingSwift"),
                                .testTarget(name: "AFNetworkingSwiftTests",
                                            dependencies: ["AFNetworkingSwift", "AFNetworking"],
                                            path: "Tests/SwiftTests",
                                            exclude: ["AlamofireTestMapping.md", "ReleaseBaseline.md"],
                                            resources: [.process("Resources")]),
                                .testTarget(name: "AFNetworkingTests",
                                            dependencies: ["AFNetworking"],
                                            path: "Tests/Tests",
                                            exclude: [
                                                "AFAutoPurgingImageCacheTests.m",
                                                "AFImageDownloaderTests.m",
                                                "AFNetworkActivityManagerTests.m",
                                                "AFUIActivityIndicatorViewTests.m",
                                                "AFUIButtonTests.m",
                                                "AFUIImageViewTests.m",
                                                "AFUIRefreshControlTests.m",
                                                "AFWKWebViewTests.m"
                                            ],
                                            resources: [
                                                .copy("HTTPBinOrgServerTrustChain"),
                                                .copy("ADNNetServerTrustChain"),
                                                .copy("GoogleComServerTrustChainPath1"),
                                                .copy("GoogleComServerTrustChainPath2"),
                                                .process("httpbinorg_02182021.cer"),
                                                .process("Amazon.cer"),
                                                .process("Amazon Root CA 1.cer"),
                                                .process("Starfield Services Root Certificate Authority - G2.cer"),
                                                .process("AltName.cer"),
                                                .process("NoDomains.cer"),
                                                .process("foobar.com.cer"),
                                                .process("google.com.cer"),
                                                .process("GoogleInternetAuthorityG2.cer"),
                                                .process("Equifax_Secure_Certificate_Authority_Root.cer"),
                                                .process("GeoTrust_Global_CA-cross.cer"),
                                                .process("GeoTrust_Global_CA_Root.cer"),
                                                .process("logo.png")
                                            ])])
