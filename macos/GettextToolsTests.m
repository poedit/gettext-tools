//
//  GettextToolsTests.m
//  GettextToolsTests
//
//  Created by Václav Slavík on 13.06.2026.
//  Copyright © 2026 Václav Slavík. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <GettextTools/GettextTools.h>

@interface GettextToolsTests : XCTestCase

@end

@implementation GettextToolsTests

- (void)testDatadirPathContainsLocaleResources
{
    NSString *datadirPath = GettextToolsDatadirPath();
    XCTAssertNotNil(datadirPath);

    NSFileManager *fileManager = NSFileManager.defaultManager;

    BOOL isDirectory = NO;
    NSString *localePath = [datadirPath stringByAppendingPathComponent:@"locale"];
    XCTAssertTrue([fileManager fileExistsAtPath:localePath isDirectory:&isDirectory]);
    XCTAssertTrue(isDirectory);

    NSString *catalogPath = [localePath stringByAppendingPathComponent:@"de/LC_MESSAGES/gettext-tools.mo"];
    isDirectory = NO;
    XCTAssertTrue([fileManager fileExistsAtPath:catalogPath isDirectory:&isDirectory]);
    XCTAssertFalse(isDirectory);
}

- (void)testBindirPathContainsMsgfmt
{
    NSString *bindirPath = GettextToolsBindirPath();
    XCTAssertNotNil(bindirPath);

    BOOL isDirectory = NO;
    XCTAssertTrue([NSFileManager.defaultManager fileExistsAtPath:bindirPath isDirectory:&isDirectory]);
    XCTAssertTrue(isDirectory);

    NSString *msgfmtPath = [bindirPath stringByAppendingPathComponent:@"msgfmt"];
    isDirectory = NO;
    XCTAssertTrue([NSFileManager.defaultManager fileExistsAtPath:msgfmtPath isDirectory:&isDirectory]);
    XCTAssertFalse(isDirectory);
}

@end
