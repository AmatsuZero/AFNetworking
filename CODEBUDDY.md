# CODEBUDDY.md

This file provides guidance to CodeBuddy Code when working with code in this repository.

## Project Overview

**AFNetworking** is a mature Objective-C networking library for iOS, macOS, watchOS, and tvOS. It was deprecated on January 17, 2023, but remains online as an archive. The library is built on top of Foundation's URL Loading System and provides high-level networking abstractions with a modular architecture.

**Status:** Archived (no further releases)
**Language:** Objective-C
**Minimum Requirements:** iOS 9+, macOS 10.10+, watchOS 2+, tvOS 9+

## Development Commands

### Building
```bash
# Open the workspace
open AFNetworking.xcworkspace

# Build specific scheme
xcodebuild -workspace AFNetworking.xcworkspace -scheme "AFNetworking" -configuration Debug

# Build for specific platform
xcodebuild -workspace AFNetworking.xcworkspace -scheme "AFNetworking iOS" -configuration Debug
xcodebuild -workspace AFNetworking.xcworkspace -scheme "AFNetworking macOS" -configuration Debug
xcodebuild -workspace AFNetworking.xcworkspace -scheme "AFNetworking tvOS" -configuration Debug
xcodebuild -workspace AFNetworking.xcworkspace -scheme "AFNetworking watchOS" -configuration Debug
```

### Running Tests
AFNetworking uses XCTest for unit testing. Tests are located in `/Tests/Tests/`.

```bash
# Run all tests using fastlane (primary test method)
fastlane ci_commit configuration:Debug --env ios13_xcode11
fastlane ci_commit configuration:Debug --env macos
fastlane ci_commit configuration:Debug --env tvos13_xcode11
fastlane ci_commit configuration:Debug --env catalyst

# Run tests directly via Xcode CLI
xcodebuild -workspace AFNetworking.xcworkspace -scheme "AFNetworking" -configuration Debug test

# Run specific test file (example)
xcodebuild -workspace AFNetworking.xcworkspace -scheme "AFNetworking" -configuration Debug test -only "AFNetworking Tests/AFURLSessionManagerTests"

# Run specific test method
xcodebuild -workspace AFNetworking.xcworkspace -scheme "AFNetworking" -configuration Debug test -only "AFNetworking Tests/AFURLSessionManagerTests/testValidatingURL"
```

### Linting and Code Quality
```bash
# Build with warnings as errors (CI configuration)
xcodebuild -workspace AFNetworking.xcworkspace -scheme "AFNetworking" -configuration Debug -strict

# Static analysis
xcodebuild analyze -workspace AFNetworking.xcworkspace -scheme "AFNetworking" -configuration Debug
```

### Swift Package Manager
```bash
# Build with SPM
swift build

# Build with SPM (verbose)
swift build -v

# Test with SPM
swift test
```

## Project Structure

AFNetworking follows a **layered, modular architecture**:

### Core Components

#### 1. Session Management (`/AFNetworking/`)
- **`AFURLSessionManager`** (~900 lines): Base class wrapping `NSURLSession`. Handles all URL session delegate protocols, task management, progress tracking, and security policy integration.
- **`AFHTTPSessionManager`**: Convenience subclass providing HTTP method shortcuts (GET, POST, PUT, PATCH, DELETE) and request/response serializer integration.

#### 2. Serialization (Protocol-based design for extensibility)
- **Request Serialization** (`<AFURLRequestSerialization>`):
  - `AFHTTPRequestSerializer`: Query string & form-encoding (default)
  - `AFJSONRequestSerializer`: JSON body encoding
  - `AFPropertyListRequestSerializer`: Property list encoding
  
- **Response Serialization** (`<AFURLResponseSerialization>`):
  - `AFHTTPResponseSerializer`: Base class with status/content-type validation
  - `AFJSONResponseSerializer`: JSON parsing with null removal
  - `AFXMLParserResponseSerializer`: SAX-based XML parsing
  - `AFXMLDocumentResponseSerializer`: DOM-based parsing (macOS only)
  - `AFPropertyListResponseSerializer`: Property list decoding
  - `AFImageResponseSerializer`: Image data decoding
  - `AFCompoundResponseSerializer`: Composite serializer supporting multiple formats

#### 3. Security (`AFSecurityPolicy`)
X.509 certificate pinning with support for:
- Full certificate pinning
- Public key pinning
- Custom SSL validation
- Challenge handling in NSURLSession delegates

#### 4. Network Monitoring (`AFNetworkReachabilityManager`)
Reachability status monitoring using SystemConfiguration framework:
- WWAN and WiFi interface detection
- Status change notifications
- Shared singleton pattern
- **Not available on watchOS**

#### 5. UIKit Integration (`/UIKit+AFNetworking/`)
Objective-C categories for seamless UIKit integration:
- **Image Management**: `AFImageDownloader` (centralized download queue), `AFAutoPurgingImageCache` (LRU cache with auto-purge)
- **UI Components**: `UIImageView+AFNetworking`, `UIButton+AFNetworking`, `UIActivityIndicatorView+AFNetworking`, `UIProgressView+AFNetworking`, `UIRefreshControl+AFNetworking`, `WKWebView+AFNetworking`
- **Activity Indicator**: `AFNetworkActivityIndicatorManager` for status bar indicator

### Key Design Patterns
- **Protocol-based design**: Serializers use protocols for extensibility
- **Category extensions**: UIKit integration via Objective-C categories
- **Delegation**: NSURLSession delegate protocols
- **Singleton pattern**: Reachability and image downloader
- **GCD for threading**: Completion queues and dispatch groups
- **LRU caching**: Auto-purging image cache with priority queues

### File Organization
```
AFNetworking/                              # Core networking (6 main files + headers)
├── AFURLSessionManager.h/m               # Base session manager
├── AFHTTPSessionManager.h/m              # HTTP convenience layer
├── AFURLRequestSerialization.h/m         # Request encoding
├── AFURLResponseSerialization.h/m        # Response decoding
├── AFSecurityPolicy.h/m                  # SSL/TLS certificate pinning
├── AFNetworkReachabilityManager.h/m      # Network reachability
└── AFNetworking.h                        # Umbrella header

UIKit+AFNetworking/                       # UIKit extensions (11 files)
├── AFImageDownloader.h/m
├── AFAutoPurgingImageCache.h/m
├── AFNetworkActivityIndicatorManager.h/m
├── UI component categories
└── UIKit+AFNetworking.h                  # Umbrella header

Tests/Tests/                              # 24 comprehensive test files
├── AFURLSessionManagerTests.m
├── Serialization tests (request/response)
├── AFSecurityPolicyTests.m
├── AFNetworkReachabilityManagerTests.m
├── AFImageDownloaderTests.m
├── UI component tests
└── AFTestCase.h/m                        # Base test class
```

## Code Style and Conventions

Follow Apple and Google Objective-C style guides with these specific requirements:

### Formatting
- **Indentation**: 4 spaces
- **Line length limit**: 150 characters
- **Control structures**: Always use braces, even for single statements
- **Spacing**: Space after keywords (`if`, `for`, `while`), around binary operators, after commas
- **Type declarations**: Space between type and asterisk (`NSString *`), no space between asterisk and variable name

### Naming
- **Classes**: Upper camel case with 2-3 letter prefix (AF for AFNetworking), e.g., `AFURLSessionManager`
- **Methods/variables**: Lower camel case, e.g., `dataTaskWithRequest:`
- **Properties**: Use `nonnull`/`nullable` modifiers for nullability
- **Constants**: `const` declarations with upper camel case
- **Macros**: `SHOUTY_SNAKE_CASE`
- **Private members**: Underscore prefix for instance variables (`_usernameTextField`)

### Best Practices
- Use nil coalescing safely (messaging nil is safe in Objective-C)
- Prefer point syntax for properties, bracket syntax for methods
- Use lightweight generics for collections: `NSArray<NSString *> *`
- Use literal syntax for NSString, NSArray, NSDictionary, NSNumber
- Avoid direct YES/NO comparisons; use `if (flag)` instead of `if (flag == YES)`
- Organize code with `#pragma mark -` for grouping related functionality

See `/Users/samzhjiang/Github/AFNetworking/.codebuddy/rules/Objc-Style.md` for complete style requirements.

## Testing Strategy

### Test Organization
- **Location**: `/Tests/Tests/`
- **Base class**: `AFTestCase.h/m` with common setup/teardown
- **Resources**: `/Tests/Resources/` contains test certificates and data
- **Test files**: 24 comprehensive test files covering all major components

### Test Coverage Areas
1. **Session managers**: Data, upload, download task creation and completion
2. **Serializers**: Request/response encoding and decoding for all formats
3. **Security**: Certificate pinning, validation, challenge handling
4. **Reachability**: Status monitoring and notifications
5. **Image downloading**: Download prioritization, caching, cell integration
6. **UIKit integration**: Category methods and data binding

### Running Tests
- Tests execute on xcodebuild via fastlane in CI
- Each platform (iOS, macOS, tvOS) has separate test targets
- watchOS is build-only (no tests due to simulator limitations)

## Common Workflows

### Adding a New Request Serializer
1. Create new class conforming to `<AFURLRequestSerialization>`
2. Implement required protocol methods for encoding parameters
3. Add unit tests in `/Tests/Tests/AFHTTPRequestSerializationTests.m`
4. Update the umbrella header

### Adding a New Response Serializer
1. Create new class conforming to `<AFURLResponseSerialization>`
2. Implement validation and deserialization logic
3. Add unit tests in `/Tests/Tests/AFHTTPResponseSerializationTests.m`
4. Update the umbrella header

### Modifying AFURLSessionManager
Core session manager changes require:
1. Testing on all supported platforms (iOS, macOS, tvOS, watchOS)
2. Unit tests for delegate callbacks and task lifecycle
3. Verification that UIKit extensions still work correctly
4. Consider backward compatibility implications

### Working with UIKit Extensions
Categories are organized by platform. When adding new category methods:
1. Add to appropriate category file (e.g., `UIImageView+AFNetworking.m`)
2. Ensure integration with `AFImageDownloader` and cache
3. Add tests in corresponding test file
4. Verify on actual devices/simulators, not just CI

## CI/CD Pipeline

GitHub Actions runs on all PRs and pushes to master:
- **macOS tests**: Xcode 11.3.1, Debug configuration
- **iOS tests**: iOS 13 simulator, Xcode 11.3.1
- **Catalyst tests**: macOS Catalyst target
- **tvOS tests**: tvOS 13 simulator
- **watchOS build**: Build only (watchOS 6.1.1)
- **SPM build**: Swift Package Manager verification

Tests use `fastlane ci_commit configuration:Debug --env [platform]` command.

## Import Structure

### Main Headers
- Include `AFNetworking/AFNetworking.h` for all core functionality
- Include `UIKit+AFNetworking/UIKit+AFNetworking.h` for UIKit extensions

### Targeted Imports
```objc
#import "AFNetworking/AFHTTPSessionManager.h"
#import "AFNetworking/AFJSONResponseSerializer.h"
#import "UIKit+AFNetworking/UIImageView+AFNetworking.h"
```

## Important Notes

- **Deprecated**: AFNetworking is no longer maintained. This is an archived repository.
- **Swift Migration**: For new Swift projects, use Alamofire instead
- **No Further Releases**: Any modifications should be forked and published separately
- **Xcode 11+**: Required for development
- **Architecture**: All changes should maintain compatibility with the modular, protocol-based design
