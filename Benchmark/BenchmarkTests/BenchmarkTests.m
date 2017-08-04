//
//  BenchmarkTests.m
//  BenchmarkTests
//
//  Created by 李传格 on 2017/5/25.
//  Copyright © 2017年 fanmei. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface BenchmarkTests : XCTestCase

@property (nonatomic, strong) NSMutableDictionary *dict;

@end

@implementation BenchmarkTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.dict = [NSMutableDictionary new];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        for (NSInteger idx = 0; idx < 100; ++idx) {
            [self.dict setObject:@(idx) forKey:@(idx)];
        }
    }];
}

@end
