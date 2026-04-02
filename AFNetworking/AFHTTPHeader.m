// AFHTTPHeader.m
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

#import "AFHTTPHeader.h"

// MARK: - AFHTTPHeader

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

+ (instancetype)accept:(NSString *)value {
    return [self headerWithName:@"Accept" value:value];
}

+ (instancetype)contentType:(NSString *)value {
    return [self headerWithName:@"Content-Type" value:value];
}

+ (instancetype)authorization:(NSString *)value {
    return [self headerWithName:@"Authorization" value:value];
}

+ (instancetype)userAgent:(NSString *)value {
    return [self headerWithName:@"User-Agent" value:value];
}

+ (instancetype)bearerAuthorization:(NSString *)token {
    NSString *value = [NSString stringWithFormat:@"Bearer %@", token];
    return [self headerWithName:@"Authorization" value:value];
}

+ (instancetype)basicAuthorizationWithUsername:(NSString *)username password:(NSString *)password {
    NSString *credential = [NSString stringWithFormat:@"%@:%@", username, password];
    NSData *data = [credential dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64 = [data base64EncodedStringWithOptions:0];
    NSString *value = [NSString stringWithFormat:@"Basic %@", base64];
    return [self headerWithName:@"Authorization" value:value];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: %@", self.name, self.value];
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[AFHTTPHeader class]]) return NO;
    AFHTTPHeader *other = (AFHTTPHeader *)object;
    return [self.name.lowercaseString isEqualToString:other.name.lowercaseString]
        && [self.value isEqualToString:other.value];
}

- (NSUInteger)hash {
    return self.name.lowercaseString.hash ^ self.value.hash;
}

- (id)copyWithZone:(NSZone *)zone {
    // Immutable, return self
    return self;
}

@end

// MARK: - AFHTTPHeaders

@interface AFHTTPHeaders ()
@property (nonatomic, strong) NSMutableArray<AFHTTPHeader *> *headers;
@end

@implementation AFHTTPHeaders

- (instancetype)init {
    self = [super init];
    if (self) {
        _headers = [NSMutableArray array];
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
        NSArray<NSString *> *sortedKeys = [dictionary.allKeys sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *name in sortedKeys) {
            [self.headers addObject:[AFHTTPHeader headerWithName:name value:dictionary[name]]];
        }
    }
    return self;
}

+ (instancetype)defaultHeaders {
    AFHTTPHeaders *headers = [[AFHTTPHeaders alloc] init];

    [headers addName:@"Accept-Encoding" value:@"br;q=1.0, gzip;q=0.9, deflate;q=0.8"];

    NSArray<NSString *> *preferredLanguages = NSLocale.preferredLanguages;
    NSUInteger count = MIN(preferredLanguages.count, 6);
    NSMutableArray<NSString *> *languageQuality = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        double quality = 1.0 - (i * 0.1);
        [languageQuality addObject:[NSString stringWithFormat:@"%@;q=%.1f", preferredLanguages[i], quality]];
    }
    [headers addName:@"Accept-Language" value:[languageQuality componentsJoinedByString:@", "]];

    return headers;
}

// MARK: - 增删改查

- (void)addHeader:(AFHTTPHeader *)header {
    NSUInteger index = [self indexForName:header.name];
    if (index != NSNotFound) {
        [self.headers replaceObjectAtIndex:index withObject:header];
    } else {
        [self.headers addObject:header];
    }
}

- (void)addName:(NSString *)name value:(NSString *)value {
    [self addHeader:[AFHTTPHeader headerWithName:name value:value]];
}

- (void)removeHeaderForName:(NSString *)name {
    NSString *lowercaseName = name.lowercaseString;
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSet];
    [self.headers enumerateObjectsUsingBlock:^(AFHTTPHeader *header, NSUInteger idx, BOOL *stop) {
        if ([header.name.lowercaseString isEqualToString:lowercaseName]) {
            [indexesToRemove addIndex:idx];
        }
    }];
    [self.headers removeObjectsAtIndexes:indexesToRemove];
}

- (nullable NSString *)valueForHeaderName:(NSString *)name {
    return [self headerForName:name].value;
}

- (nullable AFHTTPHeader *)headerForName:(NSString *)name {
    NSString *lowercaseName = name.lowercaseString;
    for (AFHTTPHeader *header in self.headers) {
        if ([header.name.lowercaseString isEqualToString:lowercaseName]) {
            return header;
        }
    }
    return nil;
}

- (void)applyToRequest:(NSMutableURLRequest *)request {
    for (AFHTTPHeader *header in self.headers) {
        [request setValue:header.value forHTTPHeaderField:header.name];
    }
}

// MARK: - Properties

- (NSArray<AFHTTPHeader *> *)allHeaders {
    return [self.headers copy];
}

- (NSDictionary<NSString *, NSString *> *)dictionary {
    NSMutableDictionary<NSString *, NSString *> *dict = [NSMutableDictionary dictionaryWithCapacity:self.headers.count];
    for (AFHTTPHeader *header in self.headers) {
        dict[header.name] = header.value;
    }
    return [dict copy];
}

- (NSUInteger)count {
    return self.headers.count;
}

// MARK: - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len {
    return [self.headers countByEnumeratingWithState:state objects:buffer count:len];
}

// MARK: - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFHTTPHeaders *copy = [[AFHTTPHeaders alloc] init];
    copy.headers = [self.headers mutableCopy];
    return copy;
}

// MARK: - Description

- (NSString *)description {
    NSMutableArray<NSString *> *descriptions = [NSMutableArray arrayWithCapacity:self.headers.count];
    for (AFHTTPHeader *header in self.headers) {
        [descriptions addObject:header.description];
    }
    return [descriptions componentsJoinedByString:@"\n"];
}

// MARK: - Private

- (NSUInteger)indexForName:(NSString *)name {
    NSString *lowercaseName = name.lowercaseString;
    for (NSUInteger i = 0; i < self.headers.count; i++) {
        if ([self.headers[i].name.lowercaseString isEqualToString:lowercaseName]) {
            return i;
        }
    }
    return NSNotFound;
}

@end
