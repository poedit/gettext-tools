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

NSString *GettextToolsPathForTool(NSString *toolName)
{
    NSBundle *bundle = [NSBundle bundleForClass:GettextToolsBundleLocator.class];
    return [bundle pathForAuxiliaryExecutable:toolName];
}
