//
//  GettextTools.m
//  GettextTools
//
//  This file is in public domain.
//

#import "GettextTools.h"

@interface GettextToolsBundleLocator : NSObject
@end

@implementation GettextToolsBundleLocator
@end

NSString *GettextToolsBindirPath(void)
{
    NSBundle *bundle = [NSBundle bundleForClass:GettextToolsBundleLocator.class];
    return [bundle.bundlePath stringByAppendingPathComponent:@"Versions/Current/Helpers"];
}

NSString *GettextToolsDatadirPath(void)
{
    NSBundle *bundle = [NSBundle bundleForClass:GettextToolsBundleLocator.class];
    return bundle.resourcePath;
}
