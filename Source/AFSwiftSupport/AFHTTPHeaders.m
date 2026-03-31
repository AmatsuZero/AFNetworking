// AFHTTPHeaders.m
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

#import "AFHTTPHeaders.h"

#pragma mark - AFHTTPHeader

@implementation AFHTTPHeader

- (instancetype)initWithName:(NSString *)name value:(NSString *)value {
    self = [super init];
    if (self) {
        _name = [name copy];
        _value = [value copy];
    }
    return self;
}

+ (instancetype)headerWithName:(NSString *)name value:(NSString *)value {
    return [[self alloc] initWithName:name value:value];
}

+ (instancetype)acceptWithValue:(NSString *)value {
    return [self headerWithName:@"Accept" value:value];
}

+ (instancetype)contentTypeWithValue:(NSString *)value {
    return [self headerWithName:@"Content-Type" value:value];
}

+ (instancetype)authorizationWithValue:(NSString *)value {
    return [self headerWithName:@"Authorization" value:value];
}

+ (instancetype)authorizationWithBearerToken:(NSString *)token {
    return [self headerWithName:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", token]];
}

+ (instancetype)authorizationWithUsername:(NSString *)username password:(NSString *)password {
    NSString *credential = [NSString stringWithFormat:@"%@:%@", username, password];
    NSData *data = [credential dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64 = [data base64EncodedStringWithOptions:0];
    return [self headerWithName:@"Authorization" value:[NSString stringWithFormat:@"Basic %@", base64]];
}

+ (instancetype)userAgentWithValue:(NSString *)value {
    return [self headerWithName:@"User-Agent" value:value];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return [[AFHTTPHeader alloc] initWithName:self.name value:self.value];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.value forKey:@"value"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSString *name = [coder decodeObjectOfClass:[NSString class] forKey:@"name"];
    NSString *value = [coder decodeObjectOfClass:[NSString class] forKey:@"value"];
    return [self initWithName:name value:value];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: %@", self.name, self.value];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[AFHTTPHeader class]]) {
        return NO;
    }
    AFHTTPHeader *other = (AFHTTPHeader *)object;
    return [self.name.lowercaseString isEqualToString:other.name.lowercaseString] &&
           [self.value isEqualToString:other.value];
}

- (NSUInteger)hash {
    return self.name.lowercaseString.hash ^ self.value.hash;
}

@end

#pragma mark - AFHTTPHeaders

@interface AFHTTPHeaders ()

@property (nonatomic, strong) NSMutableArray<AFHTTPHeader *> *mutableHeaders;

@end

@implementation AFHTTPHeaders

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableHeaders = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithHeaders:(NSArray<AFHTTPHeader *> *)headers {
    self = [self init];
    if (self) {
        for (AFHTTPHeader *header in headers) {
            [self addHeader:header];
        }
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSString *> *)dictionary {
    self = [self init];
    if (self) {
        [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSString *value, BOOL *stop) {
            [self addHeader:[AFHTTPHeader headerWithName:name value:value]];
        }];
    }
    return self;
}

+ (instancetype)headersWithHeaders:(NSArray<AFHTTPHeader *> *)headers {
    return [[self alloc] initWithHeaders:headers];
}

+ (instancetype)headersWithDictionary:(NSDictionary<NSString *, NSString *> *)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

+ (instancetype)defaultHeaders {
    AFHTTPHeaders *headers = [[self alloc] init];

    // Accept-Encoding
    NSArray<NSString *> *encodings = @[@"br", @"gzip", @"deflate"];
    NSMutableArray<NSString *> *qualifiedEncodings = [NSMutableArray array];
    for (NSUInteger i = 0; i < encodings.count; i++) {
        double quality = 1.0 - (i * 0.1);
        [qualifiedEncodings addObject:[NSString stringWithFormat:@"%@;q=%.1f", encodings[i], quality]];
    }
    [headers addHeader:[AFHTTPHeader headerWithName:@"Accept-Encoding"
                                              value:[qualifiedEncodings componentsJoinedByString:@", "]]];

    // Accept-Language
    NSMutableArray<NSString *> *languages = [NSMutableArray array];
    NSArray<NSString *> *preferredLanguages = [NSLocale preferredLanguages];
    NSUInteger languageCount = MIN(preferredLanguages.count, (NSUInteger)6);
    for (NSUInteger i = 0; i < languageCount; i++) {
        double quality = 1.0 - (i * 0.1);
        [languages addObject:[NSString stringWithFormat:@"%@;q=%.1f", preferredLanguages[i], quality]];
    }
    [headers addHeader:[AFHTTPHeader headerWithName:@"Accept-Language"
                                              value:[languages componentsJoinedByString:@", "]]];

    // User-Agent
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *appName = [bundle objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleExecutableKey] ?: @"Unknown";
    NSString *appVersion = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"Unknown";
    NSString *bundleID = [bundle bundleIdentifier] ?: @"Unknown";

#if TARGET_OS_IOS
    NSString *osName = @"iOS";
#elif TARGET_OS_WATCH
    NSString *osName = @"watchOS";
#elif TARGET_OS_TV
    NSString *osName = @"tvOS";
#elif TARGET_OS_MAC
    NSString *osName = @"macOS";
#else
    NSString *osName = @"Unknown";
#endif

    NSOperatingSystemVersion osVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSString *osVersionString = [NSString stringWithFormat:@"%ld.%ld.%ld",
                                 (long)osVersion.majorVersion,
                                 (long)osVersion.minorVersion,
                                 (long)osVersion.patchVersion];

    NSString *userAgent = [NSString stringWithFormat:@"%@/%@ (%@; %@ %@) AFNetworking",
                           appName, appVersion, bundleID, osName, osVersionString];
    [headers addHeader:[AFHTTPHeader userAgentWithValue:userAgent]];

    return headers;
}

#pragma mark - 增删改查

- (void)addHeader:(AFHTTPHeader *)header {
    // 移除同名旧值
    [self removeHeaderForName:header.name];
    [self.mutableHeaders addObject:header];
}

- (void)addName:(NSString *)name value:(NSString *)value {
    [self addHeader:[AFHTTPHeader headerWithName:name value:value]];
}

- (void)removeHeaderForName:(NSString *)name {
    NSString *lowercaseName = name.lowercaseString;
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSet];
    [self.mutableHeaders enumerateObjectsUsingBlock:^(AFHTTPHeader *header, NSUInteger idx, BOOL *stop) {
        if ([header.name.lowercaseString isEqualToString:lowercaseName]) {
            [indexesToRemove addIndex:idx];
        }
    }];
    [self.mutableHeaders removeObjectsAtIndexes:indexesToRemove];
}

- (nullable NSString *)valueForName:(NSString *)name {
    return [self headerForName:name].value;
}

- (nullable AFHTTPHeader *)headerForName:(NSString *)name {
    NSString *lowercaseName = name.lowercaseString;
    for (AFHTTPHeader *header in self.mutableHeaders) {
        if ([header.name.lowercaseString isEqualToString:lowercaseName]) {
            return header;
        }
    }
    return nil;
}

- (void)applyToURLRequest:(NSMutableURLRequest *)request {
    for (AFHTTPHeader *header in self.mutableHeaders) {
        [request setValue:header.value forHTTPHeaderField:header.name];
    }
}

- (NSUInteger)count {
    return self.mutableHeaders.count;
}

#pragma mark - 属性

- (NSArray<AFHTTPHeader *> *)headers {
    return [self.mutableHeaders copy];
}

- (NSDictionary<NSString *, NSString *> *)dictionary {
    NSMutableDictionary<NSString *, NSString *> *dict = [NSMutableDictionary dictionary];
    for (AFHTTPHeader *header in self.mutableHeaders) {
        dict[header.name] = header.value;
    }
    return [dict copy];
}

#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len {
    return [self.mutableHeaders countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFHTTPHeaders *copy = [[AFHTTPHeaders alloc] init];
    for (AFHTTPHeader *header in self.mutableHeaders) {
        [copy.mutableHeaders addObject:[header copy]];
    }
    return copy;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.mutableHeaders forKey:@"headers"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [self init];
    if (self) {
        NSSet *classes = [NSSet setWithObjects:[NSArray class], [AFHTTPHeader class], nil];
        NSArray *decoded = [coder decodeObjectOfClasses:classes forKey:@"headers"];
        if (decoded) {
            [self.mutableHeaders addObjectsFromArray:decoded];
        }
    }
    return self;
}

#pragma mark - NSObject

- (NSString *)description {
    NSMutableString *desc = [NSMutableString stringWithString:@"AFHTTPHeaders {\n"];
    for (AFHTTPHeader *header in self.mutableHeaders) {
        [desc appendFormat:@"  %@\n", header];
    }
    [desc appendString:@"}"];
    return desc;
}

@end